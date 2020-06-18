module Language.Dickinson.ScopeCheck ( checkScope
                                     ) where

import           Control.Applicative       (Alternative, (<|>))
import           Control.Monad.State       (State, evalState, get, modify)
import           Data.Foldable             (asum, traverse_)
import qualified Data.IntSet               as IS
import           Language.Dickinson.Error
import           Language.Dickinson.Name
import           Language.Dickinson.Type
import           Language.Dickinson.Unique

type CheckM = State IS.IntSet

runCheckM :: CheckM a -> a
runCheckM = flip evalState IS.empty

insertName :: Name a -> CheckM ()
insertName (Name _ (Unique i) _) = modify (IS.insert i)

deleteName :: Name a -> CheckM ()
deleteName (Name _ (Unique i) _) = modify (IS.delete i)

-- | Checks that there are not an identifiers that aren't in scope; needs to run
-- after the renamer
checkScope :: Dickinson a -> Maybe (DickinsonError a)
checkScope = runCheckM . checkDickinson

checkDickinson :: Dickinson a -> CheckM (Maybe (DickinsonError a))
checkDickinson = mapSumM checkDecl

checkDecl :: Declaration a -> CheckM (Maybe (DickinsonError a))
checkDecl Import{} = pure Nothing
checkDecl (Define _ n e) =
    insertName n *>
    checkExpr e

checkExpr :: Expression a -> CheckM (Maybe (DickinsonError a))
checkExpr Literal{}      = pure Nothing
checkExpr StrChunk{}     = pure Nothing
checkExpr (Apply _ e e') = (<|>) <$> checkExpr e <*> checkExpr e'
checkExpr (Interp _ es)  = mapSumM checkExpr es
checkExpr (Choice _ brs) = mapSumM checkExpr (snd <$> brs)
checkExpr (Concat _ es)  = mapSumM checkExpr es
checkExpr (Lambda _ n _ e) = do
    insertName n
    checkExpr e <* deleteName n
checkExpr (Var _ n@(Name _ (Unique i) l)) = do
    b <- get
    if i `IS.member` b
        then pure Nothing
        else pure $ Just (UnfoundName l n)
checkExpr (Let _ bs e) = do
    let ns = fst <$> bs
    traverse_ insertName ns
    (<|>) <$> checkExpr e <*> mapSumM checkExpr (snd <$> bs)
        <* traverse_ deleteName ns

mapSumM :: (Traversable t, Alternative f, Applicative m) => (a -> m (f b)) -> t a -> m (f b)
mapSumM = (fmap asum .) . traverse
