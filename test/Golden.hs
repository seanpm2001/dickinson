module Golden ( goldenTests
              ) where

import           Control.Exception.Value       (eitherThrow)
import qualified Data.ByteString.Lazy          as BSL
import           Data.Functor                  (void)
import           Data.Text.Lazy.Encoding       (encodeUtf8)
import           Data.Text.Prettyprint.Doc.Ext
import           Language.Dickinson.Parser
import           Language.Dickinson.Rename
import           Language.Dickinson.Type
import           Prettyprinter                 (pretty)
import           System.FilePath               ((-<.>))
import           Test.Tasty                    (TestTree, testGroup)
import           Test.Tasty.Golden             (goldenVsString)
import           Text.Pretty.Simple            (defaultOutputOptionsNoColor, outputOptionsIndentAmount, pShowOpt)

goldenTests :: TestTree
goldenTests =
    testGroup "Golden tests"
        [ withDckFile "test/data/nestLet.dck"
        , withDckFile "test/data/import.dck"
        , withDckFile "test/data/adt.dck"
        , withDckFile "test/data/escaped.dck"
        , withDckFile "test/data/nestInterp.dck"
        , renameDckFile "test/data/nestLet.dck"
        , renameDckFile "test/data/let.dck"
        , renameDckFile "test/data/multiLet.dck"
        , renameDckFile "test/data/lambda.dck"
        , renameDckFile "test/data/higherOrder.dck"
        , renameDckFile "test/data/tupleRename.dck"
        , renameDckFile "test/eval/match.dck"
        , renameDckFile "test/data/quoteify.dck"
        , withDckFile "test/data/lexDollarSign.dck"
        , withDckFile "test/data/multiStr.dck"
        , withDckFile "test/data/multiQuoteify.dck"
        , withDckFile "test/data/lambdaMultiQuote.dck"
        , withDckFile "test/eval/matchSex.dck"
        , withDckFile "test/examples/quote.dck"
        , withDckFile "test/examples/declension.dck"
        , withDckFile "test/data/refractory.dck"
        , withDckFile "test/data/imports.dck"
        ]

prettyBSL :: Dickinson a -> BSL.ByteString
prettyBSL = encodeUtf8 . dickinsonLazyText . pretty

debugBSL :: Show a => a -> BSL.ByteString
debugBSL = encodeUtf8 . pShowOpt defaultOutputOptionsNoColor { outputOptionsIndentAmount = 2 }

-- TODO: sanity check?

withDckFile :: FilePath -> TestTree
withDckFile fp =
    goldenVsString ("Matches golden output " ++ fp) (fp -<.> "pretty") act

    where act = prettyBSL . eitherThrow . parse <$> BSL.readFile fp

renameDckFile :: FilePath -> TestTree
renameDckFile fp =
    goldenVsString ("Matches golden output " ++ fp) (fp -<.> "rename") act

    where act = debugBSL . void . fst . uncurry renameDickinson . eitherThrow . parseWithMax <$> BSL.readFile fp
