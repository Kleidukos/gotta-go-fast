{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE Strict #-}

import Development.Shake
import Development.Shake.FilePath
import System.Directory qualified as Directory
import LiterateX qualified
import LiterateX.Renderer qualified as Renderer
import LiterateX.Types.SourceFormat qualified as SourceFormat
import Data.Foldable 
import Debug.Trace
import Data.Function
import Data.Map qualified as Map
import Data.Map (Map)
import Control.Monad (void, when)
import Control.Monad.IO.Class (MonadIO)
import System.IO.Strict qualified as Strict
import qualified Data.List as List

main :: IO ()
main = shakeArgs shakeOptions{shakeFiles="_build"} $ do
  action $ do
    liftIO $ Directory.createDirectoryIfMissing True "./book-src"

  phony "process" $ do
    putInfo "[+] Processing files…"
    void $ Map.traverseWithKey (\moduleDir bookDir -> do
      liftIO $ Directory.createDirectoryIfMissing True ("./book-src" </> bookDir)
      files <- getDirectoryFiles ("src/Book" </> moduleDir) ["//*.hs"]
      liftIO $ print files
      forM_ files $ \f -> do
        let fileName = traceId $ toMarkdownFile f bookDir
        liftIO $ LiterateX.transformFileToFile
          SourceFormat.DoubleDash
          (Renderer.defaultOptionsFor "haskell")
          ("src/Book" </> moduleDir </> f)
          fileName
        processFullProseModule fileName
        )
      chapters

chapters :: Map FilePath FilePath
chapters = Map.fromList
  [ ("Chapter01", "01-about")
  , ("Chapter02", "02-gotta_go_fast")
  , ("Chapter03", "03-classification")
  , ("Chapter04", "04-finding_issues")
  , ("Chapter05", "05-testing")
  , ("Chapter06", "06-case_studies")
  , ("Chapter07", "07-conclusion")
  ]

toMarkdownFile :: FilePath -> FilePath -> FilePath
toMarkdownFile f bookChapter = f
  & dropExtension
  & appendExtension ".md"
  & prependPath bookChapter
  & prependPath "book-src"

-- | Prepend the second argument to the first.
-- To be used in pipelines.
--
-- > "foobar" & prependPath "book"
-- "book/foobar"
prependPath :: FilePath -> FilePath -> FilePath
prependPath prefixPath path  = prefixPath </> path

-- | Append the first argument to the second as an extension.
-- To be used in pipelines.
--
-- > "foobar" & appendExtension ".md"
-- "foobar.md"
appendExtension :: FilePath -> FilePath -> FilePath
appendExtension extension path  = path <.> extension

processFullProseModule :: (MonadIO m) => FilePath -> m ()
processFullProseModule filepath = do
  file <- liftIO $ Strict.readFile filepath
  when ("{-# ANN module False #-}" `List.isInfixOf` file) $
    liftIO $ writeFile filepath (unlines $ List.drop 5 $ lines file)
