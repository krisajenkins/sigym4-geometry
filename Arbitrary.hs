{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE FlexibleInstances
           , FlexibleContexts
           , ScopedTypeVariables
           , UndecidableInstances
           , CPP
           #-}
module Arbitrary where

import Test.QuickCheck
#if MIN_VERSION_base(4,8,0)
import Control.Applicative ((<$>))
#else
import Control.Applicative ((<$>), (<*>))
#endif
import Data.Maybe (fromJust)
import Data.Vector (fromList)
import qualified Data.Vector.Unboxed as U

import Sigym4.Geometry

instance Arbitrary t => Arbitrary (V2 t) where
  arbitrary = V2 <$> arbitrary <*> arbitrary

instance Arbitrary t => Arbitrary (V3 t) where
  arbitrary = V3 <$> arbitrary <*> arbitrary <*> arbitrary

instance Arbitrary (Size V2) where
  arbitrary = do
    Positive w <- arbitrary
    Positive h <- arbitrary
    return $ Size $ V2 w h

instance Arbitrary (Offset t) where
  arbitrary = Offset . getNonNegative <$> arbitrary

instance Arbitrary (Size V3) where
  arbitrary = do
    Positive w <- arbitrary
    Positive h <- arbitrary
    Positive z <- arbitrary
    return $ Size $ V3 w h z

instance forall srid. Arbitrary (Extent V2 srid) where
  arbitrary = do
    lr <- arbitrary
    Positive dx <- arbitrary
    Positive dy <- arbitrary
    let d = V2 dx dy
    return $ Extent lr (lr+d)

instance Arbitrary (Vertex v) => Arbitrary (Pixel v) where
  arbitrary = Pixel <$> arbitrary

instance Arbitrary (Vertex v) => Arbitrary (Point v srid) where
    arbitrary = fmap Point arbitrary

instance (VectorSpace v, Arbitrary (Vertex v))
  => Arbitrary (MultiPoint v srid) where
    arbitrary = MultiPoint <$> fmap fromList (resized arbitrary)

instance (VectorSpace v, Arbitrary (Vertex v))
  => Arbitrary (LinearRing v srid) where
    arbitrary = do ps <- (++) <$> vector 3 <*> arbitrary
                   return . fromJust . mkLinearRing $ ps ++ [head ps]

instance (VectorSpace v, Arbitrary (Vertex v))
  => Arbitrary (LineString v srid) where
    arbitrary = fmap (fromJust . mkLineString) $ (++) <$> vector 2 <*> arbitrary

instance (VectorSpace v, Arbitrary (Vertex v))
  => Arbitrary (MultiLineString v srid) where
    arbitrary = MultiLineString <$> fmap fromList (resized arbitrary)


instance (VectorSpace v, Arbitrary (Vertex v))
  => Arbitrary (Polygon v srid) where
    arbitrary = Polygon <$> arbitrary <*> fmap fromList (resized arbitrary)

instance (VectorSpace v, Arbitrary (Vertex v))
  => Arbitrary (Triangle v srid) where
    arbitrary = do
        mRet <- mkTriangle <$> arbitrary <*> arbitrary <*> arbitrary
        maybe arbitrary return mRet

instance (VectorSpace v, Arbitrary (Vertex v))
  => Arbitrary (MultiPolygon v srid) where
    arbitrary = MultiPolygon <$> fmap fromList (resized arbitrary)

instance (VectorSpace v, Arbitrary (Vertex v))
  => Arbitrary (PolyhedralSurface v srid) where
    arbitrary = PolyhedralSurface <$> fmap fromList (resized arbitrary)

instance (VectorSpace v, Arbitrary (Vertex v))
  => Arbitrary (TIN v srid) where
    arbitrary = TIN <$> fmap U.fromList (resized arbitrary)


instance (VectorSpace v, Arbitrary (Vertex v))
  => Arbitrary (Geometry v srid) where
    arbitrary = oneof (geometryCollection:geometries)
        where
            geometryCollection = GeoCollection . GeometryCollection . fromList
                             <$> (resized $ listOf (oneof geometries))
            point = GeoPoint <$> arbitrary
            lineString = GeoLineString <$> arbitrary
            polygon = GeoPolygon <$> arbitrary
            multiPolygon = GeoMultiPolygon <$> arbitrary
            multiPoint = GeoMultiPoint <$> arbitrary
            multiLineString = GeoMultiLineString <$> arbitrary
            triangle = GeoTriangle <$> arbitrary
            tin = GeoTIN <$> arbitrary
            psurface = GeoPolyhedralSurface <$> arbitrary
            geometries = [ point, lineString, polygon
                         , multiPoint, multiLineString, multiPolygon
                         , triangle, psurface, tin
                         ]

resized :: Gen a -> Gen a
resized = resize 15
