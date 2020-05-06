module Main (main) where

import qualified Data.ByteString.Lazy as BSL
import           Data.Either          (isRight)
import           Language.Dickinson
import           Test.Tasty
import           Test.Tasty.HUnit

main :: IO ()
main =
    defaultMain $
        testGroup "Parser tests"
            [ lexNoError "test/data/const.dck"
            , parseNoError "test/data/const.dck"
            ]

parseNoError :: FilePath -> TestTree
parseNoError fp = testCase ("Parsing doesn't fail (" ++ fp ++ ")") $ do
    contents <- BSL.readFile fp
    assertBool "Doesn't fail parsing" $ isRight (parse contents)

lexNoError :: FilePath -> TestTree
lexNoError fp = testCase ("Lexing doesn't fail (" ++ fp ++ ")") $ do
    contents <- BSL.readFile fp
    assertBool "Doesn't fail lexing" $ isRight (lexDickinson contents)