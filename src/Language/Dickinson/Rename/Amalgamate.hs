{-# LANGUAGE FlexibleContexts #-}

module Language.Dickinson.Rename.Amalgamate ( amalgamateM
                                            , fileDecls
                                            , bslDecls
                                            ) where

import           Control.Composition              ((<=*<))
import           Control.Monad                    ((<=<))
import           Control.Monad.Except             (MonadError)
import           Control.Monad.IO.Class           (MonadIO)
import           Control.Monad.State              (MonadState)
import qualified Data.ByteString.Lazy             as BSL
import           Data.Functor                     (($>))
import           Data.Semigroup                   ((<>))
import           Language.Dickinson.Check.Pattern
import           Language.Dickinson.Error
import           Language.Dickinson.Lexer
import           Language.Dickinson.Lib.Get
import           Language.Dickinson.Type

withImportM :: (HasLexerState s, MonadIO m, MonadError (DickinsonError AlexPosn) m, MonadState s m)
            => [FilePath] -- ^ Includes
            -> Import AlexPosn
            -> m [Declaration AlexPosn]
withImportM is i = do
    dck <- parseImportM is i
    amalgamateM is dck

-- sequence?
amalgamateM :: (HasLexerState s, MonadIO m, MonadError (DickinsonError AlexPosn) m, MonadState s m)
            => [FilePath] -- ^ Includes
            -> Dickinson AlexPosn
            -> m [Declaration AlexPosn]
amalgamateM _ (Dickinson [] ds)    = maybeThrow (checkPatternDecl ds) $> ds
amalgamateM is (Dickinson imps ds) = do
    ids <- traverse (withImportM is) imps
    pure (concat ids <> ds)

fileDecls :: (HasLexerState s, MonadIO m, MonadError (DickinsonError AlexPosn) m, MonadState s m)
          => [FilePath] -- ^ Includes
          -> FilePath -- ^ Source file
          -> m [Declaration AlexPosn]
fileDecls is = amalgamateM is <=< parseFpM

bslDecls :: (HasLexerState s, MonadIO m, MonadError (DickinsonError AlexPosn) m, MonadState s m)
          => [FilePath] -- ^ Includes
          -> FilePath -- ^ Source file (for reporting errors)
          -> BSL.ByteString
          -> m [Declaration AlexPosn]
bslDecls is = amalgamateM is <=*< parseBSLM
