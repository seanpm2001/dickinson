-- | This module contains some bits and pieces to work with Dickinson code.
module Language.Dickinson ( -- * Parser
                            parse
                          , ParseError (..)
                          -- * Lexer
                          , lexDickinson
                          , AlexPosn
                          , Token (..)
                          -- * AST
                          , Dickinson
                          , Declaration (..)
                          , Expression (..)
                          , Builtin (..)
                          , Pattern (..)
                          , DickinsonTy (..)
                          , Name
                          , TyName
                          -- * Renamer
                          , HasRenames (..)
                          , renameExpressionM
                          -- * Imports
                          , resolveImport
                          -- * Evaluation
                          , pipelineBSL
                          , pipelineBSLErr
                          , validateBSL
                          , patternExhaustivenessBSL
                          , warnBSL
                          -- * Path
                          , defaultLibPath
                          , dckPath
                          -- * Version info
                          , dickinsonVersion
                          , dickinsonVersionString
                          ) where

import qualified Data.Version              as V
import           Language.Dickinson.File
import           Language.Dickinson.Import
import           Language.Dickinson.Lexer
import           Language.Dickinson.Lib
import           Language.Dickinson.Name
import           Language.Dickinson.Parser
import           Language.Dickinson.Rename
import           Language.Dickinson.Type
import qualified Paths_language_dickinson  as P

dickinsonVersion :: V.Version
dickinsonVersion = P.version

dickinsonVersionString :: String
dickinsonVersionString = V.showVersion dickinsonVersion
