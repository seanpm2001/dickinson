{-# LANGUAGE TransformListComp #-}

module Language.Dickinson.Check.Duplicate ( checkDuplicates
                                          ) where

import           Control.Applicative      ((<|>))
import           Data.Foldable            (toList)
import           Data.Foldable.Ext        (foldMapAlternative)
import           Data.Maybe               (mapMaybe)
import qualified Data.Text                as T
import           GHC.Exts                 (groupWith, sortWith)
import           Language.Dickinson.Error
import           Language.Dickinson.Type

-- TODO: duplicate check better? hm

checkNames :: [(a, T.Text)] -> Maybe (DickinsonWarning a)
checkNames ns = foldMapAlternative announce [ zip l x | (l, x) <- ns, then sortWith by x, then group by x using groupWith ]
    where announce (_:(l, y):_) = Just $ DuplicateStr l y
          announce _            = Nothing

-- | Check that there are not duplicates in branches.
checkDuplicates :: [Declaration a] -> Maybe (DickinsonWarning a)
checkDuplicates = foldMapAlternative checkDeclDuplicates

checkDeclDuplicates :: Declaration a -> Maybe (DickinsonWarning a)
checkDeclDuplicates (Define _ _ e) = checkExprDuplicates e
checkDeclDuplicates TyDecl{}       = Nothing

extrText :: Expression a -> Maybe (a, T.Text)
extrText (Literal l t) = pure (l, t)
extrText _             = Nothing

collectText :: [(b, Expression a)] -> [(a, T.Text)]
collectText = mapMaybe (extrText . snd)

checkExprDuplicates :: Expression a -> Maybe (DickinsonWarning a)
checkExprDuplicates Var{}              = Nothing
checkExprDuplicates Literal{}          = Nothing
checkExprDuplicates StrChunk{}         = Nothing
checkExprDuplicates (Interp _ es)      = foldMapAlternative checkExprDuplicates es
checkExprDuplicates (MultiInterp _ es) = foldMapAlternative checkExprDuplicates es
checkExprDuplicates (Concat _ es)      = foldMapAlternative checkExprDuplicates es
checkExprDuplicates (Tuple _ es)       = foldMapAlternative checkExprDuplicates es
checkExprDuplicates (Apply _ e e')     = checkExprDuplicates e <|> checkExprDuplicates e'
checkExprDuplicates (Choice _ brs)     = checkNames (collectText $ toList brs)
checkExprDuplicates (Let _ brs es)     = foldMapAlternative checkExprDuplicates (snd <$> brs) <|> checkExprDuplicates es
checkExprDuplicates (Bind _ brs es)    = foldMapAlternative checkExprDuplicates (snd <$> brs) <|> checkExprDuplicates es
checkExprDuplicates (Lambda _ _ _ e)   = checkExprDuplicates e
checkExprDuplicates (Match _ e brs)    = checkExprDuplicates e <|> foldMapAlternative (checkExprDuplicates . snd) brs
checkExprDuplicates (Flatten _ e)      = checkExprDuplicates e
checkExprDuplicates (Annot _ e _)      = checkExprDuplicates e
checkExprDuplicates Constructor{}      = Nothing
checkExprDuplicates BuiltinFn{}        = Nothing
checkExprDuplicates Random{}           = Nothing
