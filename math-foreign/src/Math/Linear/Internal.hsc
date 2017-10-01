-----------------------------------------------------------
-- |
-- module:                      Math.Linear.Internal
-- copyright:                   (c) 2016-2017 HE, Tao
-- license:                     MIT
-- maintainer:                  sighingnow@gmail.com
--
-- Interactive with blas and lapack library via FFI.
--
{-# OPTIONS_HADDOCK hide #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Math.Linear.Internal where

-- import           Control.Monad    ( when )
-- import           Data.Complex     ( Complex(..) )
-- import           Foreign.Ptr
-- import           Foreign.Storable

import Foundation
import Foundation.Class.Storable
import Foundation.Foreign
import Foundation.Primitive

import Control.Monad (when)
import GHC.Num (Num)
import qualified Foreign.Storable as Foreign.Storable

import Math.Complex

{------------------------------------------------------------------------------
-- Matrix element type classes constraints.
------------------------------------------------------------------------------}

class (PrimType a, Num a, Storable a, Foreign.Storable.Storable a) => Elem a where
    -- | Encode type into integer and tranfer it to C library.
    typeid :: a -> Int

instance Elem Float where
    typeid _ = 1
    {-# INLINE typeid #-}

instance Elem Double where
    typeid _ = 2
    {-# INLINE typeid #-}

instance Elem (Complex Float) where
    typeid _ = 3
    {-# INLINE typeid #-}

instance Elem (Complex Double) where
    typeid _ = 4
    {-# INLINE typeid #-}

-- | Handle status code returned by pure C code.
call :: Int32 -> IO ()
call status = when (status /= 0) $ error ("ffi error, return " <> show status)

{-# INLINE call #-}

-- | Handle status code returned by impure C code.
call' :: IO Int32 -> IO ()
call' status = status >>= \err -> when (err /= 0) $ error ("ffi error, return " <> show err)

{-# INLINE call' #-}

{------------------------------------------------------------------------------
-- Foreign function imports via hsc2hs.
------------------------------------------------------------------------------}

#let ccall name, args = "foreign import ccall unsafe \"linear.h %s\" c_%s :: Int -> %s\n%s :: forall a . Elem a => %s\n%s = c_%s (typeid (undefined :: a))\n{-# INLINE %s #-}", #name, #name, args, #name, args, #name, #name, #name

#ccall identity,    "Ptr a -> Int32 -> Int32 -> Int32"
#ccall random_,     "Ptr a -> Int32 -> Int32 -> IO Int32"
#ccall diag,        "Ptr a -> Int32 -> Int32 -> Ptr a -> Int32"
#ccall diagonal,    "Ptr a -> Ptr a -> Int32 -> Int32 -> Int32"
#ccall sum,         "Ptr a -> Ptr a -> Int32 -> Int32 -> Int32"
#ccall product,     "Ptr a -> Ptr a -> Int32 -> Int32 -> Int32"
#ccall mean,        "Ptr a -> Ptr a -> Int32 -> Int32 -> Int32"

#ccall lower,       "Ptr a -> Ptr a -> Int32 -> Int32 -> Int32"
#ccall upper,       "Ptr a -> Ptr a -> Int32 -> Int32 -> Int32"
#ccall transpose,   "Ptr a -> Ptr a -> Int32 -> Int32 -> Int32"

#ccall shift,       "Ptr a -> Ptr a -> Ptr a -> Int32 -> Int32 -> Int32"
#ccall times,       "Ptr a -> Ptr a -> Ptr a -> Int32 -> Int32 -> Int32"

#ccall add,         "Ptr a -> Int32 -> Int32 -> Int32 -> Ptr a -> Ptr a -> Int32"
#ccall minus,       "Ptr a -> Int32 -> Int32 -> Int32 -> Ptr a -> Ptr a -> Int32"
#ccall mult,        "Ptr a -> Int32 -> Int32 -> Int32 -> Ptr a -> Ptr a -> Int32"
#ccall division,    "Ptr a -> Int32 -> Int32 -> Int32 -> Ptr a -> Ptr a -> Int32"
#ccall dot,         "Ptr a -> Int32 -> Int32 -> Int32 -> Ptr a -> Ptr a -> Int32"

#ccall inner,       "Ptr a -> Int32 -> Ptr a -> Int32 -> Int32 -> Ptr a -> Int32 -> Int32 -> Int32"

#ccall det,         "Ptr a -> Ptr a -> Int32 -> Int32 -> Int32"
#ccall trace,       "Ptr a -> Ptr a -> Int32 -> Int32 -> Int32"
#ccall rank,        "Ptr Int32 -> Ptr a -> Int32 -> Int32 -> Int32"
#ccall norm,        "Ptr a -> Ptr a -> Int32 -> Int32 -> Int32"
#ccall inverse,     "Ptr a -> Ptr a -> Int32 -> Int32 -> Int32"

#ccall lu,          "Ptr a -> Int32 -> Int32 -> Ptr a -> Int32 -> Int32 -> Ptr a -> Int32 -> Int32 -> Ptr a -> Int32"
#ccall qr,          "Ptr a -> Int32 -> Int32 -> Ptr a -> Int32 -> Int32 -> Ptr a -> Int32 -> Int32 -> Ptr a -> Int32"
#ccall svd,         "Ptr a -> Int32 -> Int32 -> Ptr a -> Int32 -> Int32 -> Ptr a -> Int32 -> Int32 -> Ptr a -> Int32"
#ccall jordan,      "Ptr a -> Int32 -> Int32 -> Ptr a -> Int32 -> Int32 -> Ptr a -> Int32 -> Int32 -> Ptr a -> Int32"
#ccall cholesky,    "Ptr a -> Int32 -> Int32 -> Ptr a -> Int32 -> Int32 -> Ptr a -> Int32 -> Int32 -> Ptr a -> Int32"
#ccall schur,       "Ptr a -> Int32 -> Int32 -> Ptr a -> Int32 -> Int32 -> Ptr a -> Int32 -> Int32 -> Ptr a -> Int32"

#ccall transform,   "Ptr a -> Int32 -> Int32 -> Ptr a -> Ptr a -> Int32"

{------------------------------------------------------------------------------
-- Orphan instances for Int32
------------------------------------------------------------------------------}

instance IntegralCast Int32 (CountOf a) where
    integralCast = CountOf . integralUpsize
    {-# INLINE integralCast #-}

instance IntegralCast Int32 (Offset a) where
    integralCast = Offset . integralUpsize
    {-# INLINE integralCast #-}

instance IntegralDownsize (CountOf a) Int32 where
    integralDownsize (CountOf x) = integralDownsize x
    {-# INLINE integralDownsize #-}
    integralDownsizeCheck (CountOf x) = integralDownsizeCheck x
    {-# INLINE integralDownsizeCheck #-}

instance IntegralDownsize (Offset a) Int32 where
    integralDownsize (Offset x) = integralDownsize x
    {-# INLINE integralDownsize #-}
    integralDownsizeCheck (Offset x) = integralDownsizeCheck x
    {-# INLINE integralDownsizeCheck #-}
