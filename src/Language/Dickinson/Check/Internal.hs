module Language.Dickinson.Check.Internal ( sanityCheck
                                         ) where

import           Control.Monad             (when)
import           Control.Monad.State       (MonadState)
import           Language.Dickinson.Name
import           Language.Dickinson.Rename
import           Language.Dickinson.Type
import           Language.Dickinson.Unique
import           Lens.Micro.Mtl            (use)

sanityCheck :: (HasRenames s, MonadState s m) => [Declaration a] -> m ()
sanityCheck d = do
    storedMax <- use (rename.maxLens)
    let computedMax = maximum (maxUniqueDeclaration <$> d)
    when (storedMax < computedMax) $
        error "Sanity check failed!"

maxUniqueDeclaration :: Declaration a -> Int
maxUniqueDeclaration (Define _ (Name _ (Unique i) _) e) = max i (maxUniqueExpression e)

maxUniqueExpression :: Expression a -> Int
maxUniqueExpression Literal{}                     = 0
maxUniqueExpression StrChunk{}                    = 0
maxUniqueExpression (Var _ (Name _ (Unique i) _)) = i
maxUniqueExpression (Choice _ pes)                = maximum (fmap maxUniqueExpression (snd <$> pes))
maxUniqueExpression (Interp _ es)                 = maximum (fmap maxUniqueExpression es)
maxUniqueExpression (Concat _ es)                 = maximum (fmap maxUniqueExpression es)
maxUniqueExpression (Apply _ e e')                = max (maxUniqueExpression e) (maxUniqueExpression e')
maxUniqueExpression (Annot _ e _)                 = maxUniqueExpression e
maxUniqueExpression (Flatten _ e)                 = maxUniqueExpression e