{-# OPTIONS_GHC -Wno-missing-methods #-}
{-# OPTIONS_GHC -Wno-missing-pattern-synonym-signatures #-}
{-# OPTIONS_GHC -Wno-missing-signatures #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Math.Prime.FastSieve.FFI where

import Foundation
import Foundation.Foreign
import Foundation.Class.Storable
import Foundation.String (fromBytesUnsafe)

import Foreign.Marshal.Alloc (alloca)

class (PrimType ty, StorableFixed ty) => Prime ty where
    tcode :: Proxy ty -> CInt

pattern SHORT = 0
pattern USHORT = 1
pattern INT = 2
pattern UINT = 3
pattern LONG = 4
pattern ULONG = 5
pattern LONGLONG = 6
pattern ULONGLONG = 7
pattern INT16 = 8
pattern UINT16 = 9
pattern INT32 = 10
pattern UINT32 = 11
pattern INT64 = 12
pattern UINT64 = 13

instance Prime Int16 where
    tcode _ = INT16

instance Prime Int32 where
    tcode _ = INT32

instance Prime Int64 where
    tcode _ = INT64

instance Prime Word16 where
    tcode _ = UINT16

instance Prime Word32 where
    tcode _ = UINT32

instance Prime Word64 where
    tcode _ = UINT64

-- | Orphan instance for CSize as Storable.
instance Storable CSize

foreign import ccall unsafe "primesieve_generate_primes" c_generate_primes
    :: Word64 -> Word64 -> Ptr CSize -> CInt -> IO (Ptr ())

foreign import ccall unsafe "primesieve_generate_n_primes" c_generate_n_primes
    :: Word64 -> Word64 -> CInt -> IO (Ptr ())

foreign import ccall unsafe "primesieve_nth_prime" c_nth_prime
    :: Int64 -> Word64 -> Word64

foreign import ccall unsafe "primesieve_count_primes" c_count_primes
    :: Word64 -> Word64 -> Word64

foreign import ccall unsafe "primesieve_count_twins" c_count_twins
    :: Word64 -> Word64 -> Word64

foreign import ccall unsafe "primesieve_count_triplets" c_count_triplets
    :: Word64 -> Word64 -> Word64

foreign import ccall unsafe "primesieve_count_quadruplets" c_count_quadruplets
    :: Word64 -> Word64 -> Word64

foreign import ccall unsafe "primesieve_count_quintuplets" c_count_quintuplets
    :: Word64 -> Word64 -> Word64

foreign import ccall unsafe "primesieve_count_sextuplets" c_count_sextuplets
    :: Word64 -> Word64 -> Word64

foreign import ccall unsafe "primesieve_print_primes" c_print_primes
    :: Word64 -> Word64 -> IO ()

foreign import ccall unsafe "primesieve_print_twins" c_print_twins
    :: Word64 -> Word64 -> IO ()

foreign import ccall unsafe "primesieve_print_triplets" c_print_triplets
    :: Word64 -> Word64 -> IO ()

foreign import ccall unsafe "primesieve_print_quadruplets" c_print_quadruplets
    :: Word64 -> Word64 -> IO ()

foreign import ccall unsafe "primesieve_print_quintuplets" c_print_quintuplets
    :: Word64 -> Word64 -> IO ()

foreign import ccall unsafe "primesieve_print_sextuplets" c_print_sextuplets
    :: Word64 -> Word64 -> IO ()

foreign import ccall unsafe "primesieve_get_max_stop" c_get_max_stop
    :: Word64

foreign import ccall unsafe "primesieve_set_sieve_size" c_set_sieve_size
    :: CInt -> IO ()

foreign import ccall unsafe "primesieve_set_num_threads" c_set_num_threads
    :: CInt -> IO ()

-- | Deallocate a primes array created using the primesieve_generate_primes() or primesieve_generate_n_primes()
foreign import ccall unsafe "primesieve_free" c_primesieve_free
    :: Ptr () -> IO ()

foreign import ccall unsafe "primesieve_version" c_version
    :: IO (Ptr Word8)

-- | Get an array with the primes inside the interval [start, stop].
generatePrimes :: forall ty. Prime ty
    => Word64           -- ^ start
    -> Word64           -- ^ end
    -> IO (UArray ty)
generatePrimes start end = alloca $ \psz -> do
    p <- c_generate_primes start end psz (tcode (Proxy :: Proxy ty))
    sz <- peek psz
    arr <- peekArray (CountOf . fromIntegral $ sz) (castPtr p)
    c_primesieve_free p -- free the memory allocated by primesieve.
    return arr

-- | Get an array with the first n primes >= start.
generateNPrimes :: forall ty. Prime ty
    => Word64           -- ^ n
    -> Word64           -- ^ start
    -> IO (UArray ty)
generateNPrimes n start = do
    p <- c_generate_n_primes n start (tcode (Proxy :: Proxy ty))
    arr <- peekArray (CountOf . fromIntegral $ n) (castPtr p)
    c_primesieve_free p -- free the memory allocated by primesieve.
    return arr

-- | Find the nth prime.
--
--      * if n = 0 finds the 1st prime >= start,
--      * if n > 0 finds the nth prime > start,
--      * if n < 0 finds the nth prime < start (backwards).
nthPrime ::
       Int64    -- ^ n
    -> Word64   -- ^ start
    -> Word64
nthPrime = c_nth_prime

-- | Count the primes within the interval [start, stop].
countPrimes ::
       Word64   -- ^ start
    -> Word64   -- ^ end
    -> Word64
countPrimes = c_count_primes

-- | Count the twins within the interval [start, stop].
countTwins ::
       Word64   -- ^ start
    -> Word64   -- ^ end
    -> Word64
countTwins = c_count_twins

-- | Count the triplets within the interval [start, stop].
countTriplets ::
       Word64   -- ^ start
    -> Word64   -- ^ end
    -> Word64
countTriplets = c_count_triplets

-- | Count the quadruplets within the interval [start, stop].
countQuadruplets ::
       Word64   -- ^ start
    -> Word64   -- ^ end
    -> Word64
countQuadruplets = c_count_quadruplets

-- | Count the quintuplets within the interval [start, stop].
countQuintuplets ::
       Word64   -- ^ start
    -> Word64   -- ^ end
    -> Word64
countQuintuplets = c_count_quintuplets

-- | Count the sextuplets within the interval [start, stop].
countSextuplets ::
       Word64   -- ^ start
    -> Word64   -- ^ end
    -> Word64
countSextuplets = c_count_sextuplets

-- | Print the primes within the interval [start, stop] to the standard output.
printPrimes ::
       Word64   -- ^ start
    -> Word64   -- ^ end
    -> IO ()
printPrimes = c_print_primes

-- | Print the prime twins within the interval [start, stop] to the standard output.
printTwins ::
       Word64   -- ^ start
    -> Word64   -- ^ end
    -> IO ()
printTwins = c_print_twins

-- | Print the prime triplets within the interval [start, stop] to the standard output.
printTriplets ::
       Word64   -- ^ start
    -> Word64   -- ^ end
    -> IO ()
printTriplets = c_print_triplets

-- | Print the prime quadruplets within the interval [start, stop] to the standard output.
printQuadruplets ::
       Word64   -- ^ start
    -> Word64   -- ^ end
    -> IO ()
printQuadruplets = c_print_quadruplets

-- | Print the prime quintuplets within the interval [start, stop] to the standard output.
printQuintuplets ::
       Word64   -- ^ start
    -> Word64   -- ^ end
    -> IO ()
printQuintuplets = c_print_quintuplets

-- | Print the prime sextuplets within the interval [start, stop] to the standard output.
printSextuplets ::
       Word64   -- ^ start
    -> Word64   -- ^ end
    -> IO ()
printSextuplets = c_print_sextuplets

-- | Returns the largest valid stop number for primesieve, 2^64-1 (UINT64_MAX).
getMaxStop :: Word64
getMaxStop = c_get_max_stop

-- | Set the sieve size in kilobytes.
-- The best sieving performance is achieved with a sieve size of your CPU's L1 or L2 cache size (per core).
setSieveSize :: Int -> IO ()
setSieveSize = c_set_sieve_size . fromIntegral

-- | Set the number of threads for use in primesieve_count_*() and primesieve_nth_prime().
-- By default all CPU cores are used.
setNumThreads :: Int -> IO ()
setNumThreads = c_set_num_threads . fromIntegral

-- | Get the primesieve version number, in the form "i.j".
primesieveVersion :: IO String
primesieveVersion = c_version >>= (fromBytesUnsafe <$>) . peekArrayEndedBy 0
