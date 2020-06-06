module Language.Dickinson ( parse
                          , lexDickinson
                          , prettyDickinson
                          , renameDickinson
                          -- * Types
                          , Dickinson
                          , Declaration (..)
                          , evalFile
                          -- * Reëxports from
                          -- "Data.Text.Prettyprint.Doc.Render.Text"
                          , renderLazy
                          , renderStrict
                          , Pretty (pretty)
                          , putDoc
                          ) where

import           Control.Monad                         ((<=<))
import           Data.Bifunctor                        (first)
import           Data.ByteString.Lazy                  as BSL
import qualified Data.Text                             as T
import           Data.Text.Prettyprint.Doc             (Pretty (pretty))
import           Data.Text.Prettyprint.Doc.Render.Text (putDoc, renderLazy,
                                                        renderStrict)
import           Language.Dickinson.Error
import           Language.Dickinson.Eval
import           Language.Dickinson.Lexer
import           Language.Dickinson.Name
import           Language.Dickinson.Parser
import           Language.Dickinson.Pretty
import           Language.Dickinson.Rename
import           Language.Dickinson.Type

-- TODO: runDeclarationM
evalFile :: FilePath -> IO T.Text
evalFile = fmap yeet . evalIO initRenames . evalExpressionM . yeet . findMain . yeet . parse <=< BSL.readFile
-- TODO: renameDickinson

yeet :: Show a => Either a x -> x
yeet = either (error.show) id
