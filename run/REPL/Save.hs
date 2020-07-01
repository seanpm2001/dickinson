module REPL.Save ( decodeReplSt
                 , encodeReplSt
                 ) where

import qualified Codec.Compression.Zstd.Lazy as Zstd
import           Data.Binary                 (Binary, Get, Put, get, put)
import           Data.Binary.Get             (runGet)
import           Data.Binary.Put             (runPut)
import qualified Data.ByteString.Lazy        as BSL
import qualified Data.Map                    as M
import           Data.Semigroup              ((<>))
import qualified Data.Text                   as T
import           Language.Dickinson.Eval
import           Language.Dickinson.Lexer
import           Language.Dickinson.Name
import           Language.Dickinson.Unique

dropScd :: AlexUserState -> (UniqueCtx, M.Map T.Text Int, NameEnv AlexPosn)
dropScd (x, _, y, z) = (x, y, z)

addScd :: (UniqueCtx, M.Map T.Text Int, NameEnv AlexPosn) -> AlexUserState
addScd (x, y, z) = (x, scdInitState, y, z)

getReplState :: Binary a => [Double] -> Get (EvalSt a)
getReplState ds =
    EvalSt ds
        <$> get
        <*> get
        <*> get
        <*> (addScd <$> get)
        <*> get

putReplState :: Binary a => EvalSt a -> Put
putReplState (EvalSt _ be rs t lSt ty) =
       put be
    <> put rs
    <> put t
    <> put (dropScd lSt)
    <> put ty

decodeReplSt :: Binary a => [Double] -> BSL.ByteString -> EvalSt a
decodeReplSt ds = runGet (getReplState ds) . Zstd.decompress

encodeReplSt :: Binary a => EvalSt a -> BSL.ByteString
encodeReplSt = Zstd.compress 3 . runPut . putReplState
