{-#LANGUAGE ForeignFunctionInterface#-}
{-#LANGUAGE ScopedTypeVariables#-}
{-#LANGUAGE RecordWildCards#-}

module System.SysInfo
  ( sysInfo
  , SysInfo(..)
  , Loads(..)
  ) where

#include <sys/sysinfo.h>

import Foreign.C
import Foreign.Ptr
import Foreign.C.Error
import Foreign.Storable
import Foreign.Marshal.Alloc

data SysInfo = SysInfo
  { uptime :: CLong
  , loads :: Loads
  , totalram :: CULong
  , freeram :: CULong
  , sharedram :: CULong
  , bufferram :: CULong
  , totalswap :: CULong
  , freeswap :: CULong
  , procs :: CUShort
  , totalhigh :: CULong
  , freehigh :: CULong
  , memUnit :: CUInt
  } deriving (Show, Eq, Ord)

newtype Loads = Loads
  { sloads :: [CULong]
  } deriving (Show, Eq, Ord)

instance Storable Loads where
  sizeOf _ = (sizeOf (undefined :: CULong)) * 3
  alignment _ = alignment (undefined :: CULong)
  peek ptr = do
    (vals :: [CULong]) <- mapM (peekElemOff ptr') index
    return $ Loads vals
    where
      ptr' = castPtr ptr
      index = [0, 1, 2]
  poke ptr (Loads val) = mapM_ (\(v, i) -> pokeElemOff ptr' i v) (zip val index)
    where
      (ptr' :: Ptr CULong) = castPtr ptr
      index = [0, 1, 2]

instance Storable SysInfo where
  sizeOf _ = (#size struct sysinfo)
  alignment _ = (#alignment struct sysinfo)
  peek ptr = do
    uptime <- (#peek struct sysinfo, uptime) ptr
    loads <- (#peek struct sysinfo, loads) ptr
    totalram <- (#peek struct sysinfo, totalram) ptr
    freeram <- (#peek struct sysinfo, freeram) ptr
    sharedram <- (#peek struct sysinfo, sharedram) ptr
    bufferram <- (#peek struct sysinfo, bufferram) ptr
    totalswap <- (#peek struct sysinfo, totalswap) ptr
    freeswap <- (#peek struct sysinfo, freeswap) ptr
    procs <- (#peek struct sysinfo, procs) ptr
    totalhigh <- (#peek struct sysinfo, totalhigh) ptr
    freehigh <- (#peek struct sysinfo, freehigh) ptr
    memUnit <- (#peek struct sysinfo, mem_unit) ptr
    return $
      SysInfo
      { ..
      }
  poke ptr (SysInfo {..}) = do
    (#poke struct sysinfo, uptime) ptr uptime
    (#poke struct sysinfo, loads) ptr loads
    (#poke struct sysinfo, totalram) ptr totalram
    (#poke struct sysinfo, freeram) ptr freeram
    (#poke struct sysinfo, sharedram) ptr sharedram
    (#poke struct sysinfo, bufferram) ptr bufferram
    (#poke struct sysinfo, totalswap) ptr totalswap
    (#poke struct sysinfo, freeswap) ptr freeswap
    (#poke struct sysinfo, procs) ptr procs
    (#poke struct sysinfo, totalhigh) ptr totalhigh
    (#poke struct sysinfo, freehigh) ptr freehigh
    (#poke struct sysinfo, mem_unit) ptr memUnit

foreign import ccall safe "sysinfo" c_sysinfo ::
               Ptr SysInfo -> IO CInt

sysInfo :: IO (Either Errno SysInfo)
sysInfo = do
  (sptr :: Ptr SysInfo) <- malloc
  res <- c_sysinfo sptr
  if (res == 0)
    then do
      val <- peek sptr
      free sptr
      return $ Right val
    else do
      free sptr
      err <- getErrno
      return $ Left err
