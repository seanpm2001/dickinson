module Main (main) where

import           Data.Semigroup
import qualified Data.Text.IO        as TIO
import           Language.Dickinson
import           Options.Applicative
import           REPL

-- TODO debug/verbosity options...
data Act = Run !FilePath
         | REPL ![FilePath]
         | Check !FilePath
         -- CHECK subcommand (scoping &c.)

main :: IO ()
main = run =<< execParser wrapper

-- TODO: cache/"compile" &c.

act :: Parser Act
act = hsubparser
    (command "run" (info runP (progDesc "Execute a file"))
    <> command "repl" (info replP (progDesc "Start a REPL"))
    <> command "check" (info checkP (progDesc "Check that some code is valid."))
    )

replP :: Parser Act
replP = REPL <$> many dckFile

runP :: Parser Act
runP = Run <$> dckFile

checkP :: Parser Act
checkP = Check <$> dckFile

dckFile :: Parser FilePath
dckFile = argument str
    (metavar "FILE"
    <> help "Source file"
    <> dckCompletions)

dckCompletions :: HasCompleter f => Mod f a
dckCompletions = completer . bashCompleter $ "file -X '*.dck' -o plusdirs"

wrapper :: ParserInfo Act
wrapper = info (helper <*> versionMod <*> act)
    (fullDesc
    <> progDesc "Dickinson text-generation language"
    <> header "Dickinson - a text-generation language")

versionMod :: Parser (a -> a)
versionMod = infoOption languageDickinsonVersionString (short 'V' <> long "version" <> help "Show version")

run :: Act -> IO ()
run (Run fp)  = TIO.putStrLn =<< evalFile fp
run (REPL _)  = dickinsonRepl
run (Check f) = checkFile f
