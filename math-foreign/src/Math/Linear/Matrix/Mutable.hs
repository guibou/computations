-----------------------------------------------------------
-- |
-- module:                      Math.Linear.Matrix.Mutable
-- copyright:                   (c) 2016-2017 HE, Tao
-- license:                     MIT
-- maintainer:                  sighingnow@gmail.com
--
-- Multiple dimensions matrices repersentation in Haskell.
--
{-# OPTIONS_GHC -fprint-explicit-kinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module Math.Linear.Matrix.Mutable
    ( module Math.Linear.Matrix.Mutable
    , MutElemWise (..)
    ) where

import Foundation
import Foundation.Class.Storable
import Foundation.Collection
import Foundation.Primitive

import GHC.TypeLits
import Unsafe.Coerce (unsafeCoerce)

import GHC.Num (Num)
import Control.Monad.ST (RealWorld)
import Foreign.Marshal.Alloc (alloca)

import qualified Math.Linear.Internal as I
import Math.Linear.ElemWise
import Math.Linear.Vector

data MMat a (m :: Nat) (n :: Nat) s = MM
    { vect :: MVec a (m * n) s -- ^ data in plain vector.
    }

type instance Element (MMat a m n s) = a

type IOMat a m n = MMat a m n RealWorld

type STMat a m n s = MMat a m n s

-- | If the matrix is empty.
null :: forall a m n s. (KnownNat m, KnownNat n)
    => MMat a m n s -> Bool
null _ = isJust (sameNat (Proxy :: Proxy m) (Proxy :: Proxy 0)) && isJust (sameNat (Proxy :: Proxy n) (Proxy :: Proxy 0))

{-# INLINE null #-}

-- | If the matrix is a square matrix.
square :: forall a m n s. (KnownNat m, KnownNat n)
    => MMat a m n s -> Bool
square _ = isJust (sameNat (Proxy :: Proxy m) (Proxy :: Proxy n))

{-# INLINE square #-}

-- | Construct a new matrix without initialisation.
new :: (PrimMonad monad, PrimType a, KnownNat m, KnownNat n, KnownNat (m * n))
    => proxy m -> proxy n -> monad (MMat a m n (PrimState monad))
new ~_ ~_ = MM <$> mutNew undefined

{-# INLINE new #-}

-- | Construct a matrix with all zeros.
zeros :: (PrimMonad monad, PrimType a, Num a, KnownNat m, KnownNat n, KnownNat (m * n))
    => proxy m -> proxy n -> monad (MMat a m n (PrimState monad))
zeros r c = replicate' r c 0

{-# INLINE zeros #-}

-- | Construct a matrix with all ones.
ones :: (PrimMonad monad, PrimType a, Num a, KnownNat m, KnownNat n, KnownNat (m * n))
    => proxy m -> proxy n -> monad (MMat a m n (PrimState monad))
ones r c = replicate' r c 1

{-# INLINE ones #-}

-- | Construct a identity matrix, square is not required.
identity :: (I.Elem a, KnownNat m, KnownNat n, KnownNat (m * n))
    => proxy m -> proxy n -> IO (IOMat a m n)
identity r c = do
    m <- new r c
    unsafeWith m $ \xs r' c' -> I.call $ I.identity xs r' c'
    return m

{-# INLINE identity #-}

-- | Construct a identity matrix, square is not required.
random :: (I.Elem a, KnownNat m, KnownNat n, KnownNat (m * n))
    => proxy m -> proxy n -> IO (IOMat a m n)
random r c = do
    m <- new r c
    unsafeWith m $ \xs r' c' -> I.call' $ I.random_ xs r' c'
    return m

{-# INLINE random #-}

-- | Construct a matrix with all given constants.
replicate' :: (PrimMonad monad, PrimType a, KnownNat m, KnownNat n, KnownNat (m * n))
    => proxy m -> proxy n -> a -> monad (MMat a m n (PrimState monad))
replicate' m n v = MM <$> thaw (replicate (integralCast (r * c)) v)
    where r = natVal m
          c = natVal n

{-# INLINE replicate' #-}

-- | Get specified element from matrix unsafely.
(!) :: (PrimMonad monad, PrimType a, KnownNat m, KnownNat n, KnownNat (m * n))
    => MMat a m n (PrimState monad) -> (proxy m, proxy n) -> monad a
(!) = uncurry . unsafeRead

{-# INLINE (!) #-}

instance (I.Elem a, KnownNat m, KnownNat n, KnownNat (m * n)) => MutElemWise (MMat a m n RealWorld) where
    -- * tensor and scalar
    shift' x m = do
        unsafeWith m $ \xs r c ->
            alloca $ \p -> do
                poke p x
                I.call $ I.shift xs p xs r c
        return ()
    times' x m = do
        unsafeWith m $ \xs r c ->
            alloca $ \p -> do
                poke p x
                I.call $ I.times xs p xs r c
        return ()
    -- * negative
    negative' m = do
        unsafeWith m $ \xs r c ->
            I.call $ I.negative xs xs r c
        return ()
    -- -- * arithmetic
    add' m1 m2 = do
        unsafeWith m1 $ \xs1 r1 c1 ->
            unsafeWith m2 $ \xs2 _ c2 ->
                I.call $ I.add xs1 r1 c2 c1 xs1 xs2
        return ()
    minus' m1 m2 = do
        unsafeWith m1 $ \xs1 r1 c1 ->
            unsafeWith m2 $ \xs2 _ c2 ->
                I.call $ I.minus xs1 r1 c2 c1 xs1 xs2
        return ()
    mult' m1 m2 = do
        unsafeWith m1 $ \xs1 r1 c1 ->
            unsafeWith m2 $ \xs2 _ c2 ->
                I.call $ I.mult xs1 r1 c2 c1 xs1 xs2
        return ()
    division' m1 m2 = do
        unsafeWith m1 $ \xs1 r1 c1 ->
            unsafeWith m2 $ \xs2 _ c2 ->
                I.call $ I.division xs1 r1 c2 c1 xs1 xs2
        return ()
    -- * data generation
    constreplic' x = do
        m' <- new (Proxy @m) (Proxy @n)
        unsafeWith m' $ \pm' row column ->
            alloca $ \p -> do
                poke p x
                I.call $ I.replicate pm' p (row * column)
        return m'
    -- * extensions
    logistic' m = do
        unsafeWith m $ \xs r c ->
            I.call $ I.logistic xs xs r c
        return ()
    logisticd' m = do
        unsafeWith m $ \xs r c ->
            I.call $ I.logisticd xs xs r c
        return ()

-- | Read value from matrix.
read :: forall monad a m n u v proxy. (PrimMonad monad, PrimType a, KnownNat m, KnownNat n, KnownNat u, KnownNat v, KnownNat (m * n), u <= m, v <= n)
    => MMat a m n (PrimState monad) -> proxy u -> proxy v -> monad a
read MM{..} _ _ = mutRead vect (unsafeCoerce (Proxy :: Proxy (u * m + v)))

{-# INLINE read #-}

-- | Write value to matrix.
write :: forall monad a m n u v proxy. (PrimMonad monad, PrimType a, KnownNat m, KnownNat n, KnownNat u, KnownNat v, KnownNat (m * n), u <= m, v <= n)
    => MMat a m n (PrimState monad) -> proxy u -> proxy v -> a -> monad ()
write MM{..} _ _ = mutWrite vect (unsafeCoerce (Proxy :: Proxy (u * m + v)))

{-# INLINE write #-}

-- -- | Copy one matrix to another.
-- copy
--     :: (PrimMonad m, I.Elem a)
--     => MMat (PrimState m) a -> MMat (PrimState m) a -> m ()
-- copy m1 m2 = V.copy (vect m1) (vect m2)

-- {-# INLINE copy #-}

-- -- | Modify element in matrix using given function.
-- modify
--     :: (PrimMonad m, I.Elem a)
--     => MMat (PrimState m) a -> (a -> a) -> Int -> Int -> m ()
-- modify M {..} f r c = V.modify vect f (r * column + c)

-- {-# INLINE modify #-}

unsafeRead :: forall monad a m n u v proxy. (PrimMonad monad, PrimType a, KnownNat m, KnownNat n, KnownNat u, KnownNat v, KnownNat (m * n), u <= m, v <= n)
    => MMat a m n (PrimState monad) -> proxy u -> proxy v -> monad a
unsafeRead MM{..} _ _ = mutUnsafeRead vect (unsafeCoerce (Proxy :: Proxy (u * m + v)))

{-# INLINE unsafeRead #-}

unsafeWrite :: forall monad a m n u v proxy. (PrimMonad monad, PrimType a, KnownNat m, KnownNat n, KnownNat u, KnownNat v, KnownNat (m * n), u <= m, v <= n)
    => MMat a m n (PrimState monad) -> proxy u -> proxy v -> a -> monad ()
unsafeWrite MM{..} _ _ = mutUnsafeWrite vect (unsafeCoerce (Proxy :: Proxy (u * m + v)))

{-# INLINE unsafeWrite #-}

-- unsafeCopy
--     :: (PrimMonad m, I.Elem a)
--     => MMat (PrimState m) a -> MMat (PrimState m) a -> m ()
-- unsafeCopy m1 m2 = V.unsafeCopy (vect m1) (vect m2)

-- {-# INLINE unsafeCopy #-}

-- unsafeModify
--     :: (PrimMonad m, I.Elem a)
--     => MMat (PrimState m) a -> (a -> a) -> Int -> Int -> m ()
-- unsafeModify M {..} f r c = V.unsafeModify vect f (r * column + c)

-- {-# INLINE unsafeModify #-}

unsafeWith :: forall monad a b m n. (PrimMonad monad, PrimType a, KnownNat m, KnownNat n)
    => MMat a m n (PrimState monad) -> (Ptr a -> Int32 -> Int32 -> monad b) -> monad b
unsafeWith MM{..} f = withMutableVPtr vect $ \p -> f p row column
    where row = integralDownsize $ natVal (Proxy :: Proxy m)
          column = integralDownsize $ natVal (Proxy :: Proxy n)

{-# INLINE unsafeWith #-}

withMutableMPtr :: (PrimMonad monad, PrimType a) => MMat a m n (PrimState monad) -> (Ptr a -> monad b) -> monad b
withMutableMPtr MM{..} = withMutableVPtr vect

{-# INLINE withMutableMPtr #-}
