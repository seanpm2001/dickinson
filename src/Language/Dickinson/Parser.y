{
    module Language.Dickinson.Parser ( parse
                                     , ParseError (..)
                                     ) where

import Control.Monad.Except (ExceptT, runExceptT, throwError)
import Control.Monad.Trans.Class (lift)
import qualified Data.ByteString.Lazy as BSL
import qualified Data.Text as T
import Data.Text.Encoding (decodeUtf8)
import Language.Dickinson.Lexer
import Language.Dickinson.Type

}

%name parseDickinson Dickinson
%tokentype { Token AlexPosn }
%error { parseError }
%monad { Parse } { (>>=) } { pure }
%lexer { lift alexMonadScan >>= } { EOF _ }

%token
    
    lparen { TokSym $$ LParen }
    rparen { TokSym $$ RParen }

    def { TokKeyword $$ Def }

    ident { $$@(TokIdent _ _) }

    stringLiteral { $$@(TokString _ _) }

%%

many(p)
    : many(p) p { $2 : $1 }
    | { [] }

some(p)
    : many(p) p { $2 :| $1 }

Dickinson :: { Dickinson PreName AlexPosn }
          : many(Declaration) { $1 }

Declaration :: { Declaration PreName AlexPosn }
            : def Name Expression { Define $1 $2 $3 }

Name :: { PreName AlexPosn }
     : ident { PreName (loc $1) (decodeUtf8 $ BSL.toStrict $ ident $1) }

Expression :: { Expression AlexPosn }
           : stringLiteral { Literal (loc $1) (str $1) }

{

parseError :: Token AlexPosn -> Parse a
parseError = throwError . Unexpected

data ParseError a = Unexpected (Token a)
                  | LexErr String

type Parse = ExceptT (ParseError AlexPosn) Alex

data PreName a = PreName a !T.Text

parse :: BSL.ByteString -> Either (ParseError AlexPosn) (Dickinson PreName AlexPosn)
parse str = liftErr $ runAlex str (runExceptT parseDickinson)
    where liftErr (Left err) = Left (LexErr err)
          liftErr (Right (Left err)) = Left err
          liftErr (Right (Right x)) = Right x

}
