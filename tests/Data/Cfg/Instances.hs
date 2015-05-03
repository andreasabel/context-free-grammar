{-# LANGUAGE FlexibleInstances #-} -- because "Int Int" isn't "t nt"
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Data.Cfg.Instances() where

import Control.Monad(forM)
import Data.Char(toLower, toUpper)
import Data.Cfg.Augment(AugNT(..), AugT(..))
import Data.Cfg.Cfg(V(..))
import Data.Cfg.FreeCfg(FreeCfg(..))
import Data.Cfg.EpsilonProductions(EP(..))
import Data.Cfg.LeftRecursion(LR(..))
import Data.Cfg.Pretty(Pretty(..))
import qualified Data.Map as M
import qualified Data.Set as S
import Test.QuickCheck(Arbitrary(..), choose, elements, vectorOf)
import Text.PrettyPrint

base26 :: Int -> String
base26 n'
    | n' < 26	= [digitToChar n']
    | otherwise = if msds == 0
		      then [digitToChar lsd]
		      else base26 msds ++ [digitToChar lsd]
    where
    (msds, lsd) = n' `divMod` 26

    digitToChar :: Int -> Char
    digitToChar digit = toEnum (fromEnum 'a' + digit)

instance Show (FreeCfg Int Int) where
    show = show . pretty

instance Arbitrary (FreeCfg Int Int) where
    arbitrary = do
	tCnt <- choose (1, tMAX)
	let ts = [0..tCnt-1]
	ntCnt <- choose (1, ntMAX)
	let nts = [0..ntCnt-1]
	let vs = map T ts ++ map NT nts
	pairs <- forM nts $ \nt -> do
	    let genV = elements vs
	    vsCnt <- choose (0, vsMAX)
	    let genVs = vectorOf vsCnt genV
	    altCnt <- choose (1, altMAX)
	    rhss <- vectorOf altCnt genVs
	    return (nt, S.fromList rhss)

	let map' = M.fromList pairs
	return FreeCfg {
	    nonterminals' = S.fromList nts,
	    terminals' = S.fromList ts,
	    productionRules' = (map' M.!),
	    startSymbol' = 0
	    }

	where
	tMAX = 25
	-- ntMAX = 100
	ntMAX = 8
	-- vsMAX = 8
	vsMAX = 6
	altMAX = 5

------------------------------------------------------------

instance Pretty (V Int Int) where
    pretty v = text $ map f $ base26 n
	where
	(f, n) = case v of
		     NT n' -> (toLower, n')
		     T n' -> (toUpper, n')

instance Pretty (V Int (EP Int)) where
    pretty v = text $ f $ base26 n
	where
	(f, n) = case v of
		     NT n' -> case n' of
			 EP n'' -> (map toLower, n'')
			 EPStart n'' -> (toLowerStart, n'')
		     T n' -> (map toUpper, n')
	toLowerStart :: String -> String
	toLowerStart = (++ "$start") . map toLower

instance Show (FreeCfg Int (EP Int)) where
    show = show . pretty


instance Pretty (V String String) where
    pretty v = text $ case v of
			  NT nt -> nt
			  T t -> t

instance Pretty (V String (EP String)) where
    pretty v = text $ case v of
			  NT (EP nt) -> nt
			  NT (EPStart nt) -> nt ++ "_start"
			  T t -> t

instance Pretty (V String (LR String)) where
    pretty v = text $ case v of
			  NT (LR nt) -> nt
			  NT (LRTail nt) -> nt ++ "_tail"
			  T t -> t

instance Pretty (V (AugT String) (AugNT String)) where
    pretty v = text $ case v of
			  NT nt -> case nt of
			      StartSymbol -> "$start"
			      AugNT s -> s
			  T t -> case t of
			      EOF -> "$EOF"
			      AugT s -> s

-- temporary for development of left-recursion
instance Show (FreeCfg String (LR (EP String))) where
    show = show . pretty

instance Pretty (V String (LR (EP String))) where
    pretty v = text $ case v of
			  NT (LR ep) -> map toLower $ f ep
                          NT (LRTail ep) -> map toLower (f ep ++ "_tail")
                          T str -> map toUpper str
        where
        f ep = case ep of
            EP nt -> nt
            EPStart nt -> nt ++ "_start"

instance Show (FreeCfg Int (LR (EP Int))) where
    show = show . pretty

instance Pretty (V Int (LR (EP Int))) where
    pretty v = text $ case v of
                          NT (LR ep) -> map toLower $ f ep
                          NT (LRTail ep) -> map toLower (f ep ++ "_tail")
                          T t -> map toUpper $ base26 t
        where
        f ep = case ep of
            EP nt -> base26 nt
            EPStart nt -> base26 nt ++ "_start"
