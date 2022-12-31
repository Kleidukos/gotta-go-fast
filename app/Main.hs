{-# LANGUAGE OverloadedStrings #-}
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
import Control.Monad (void)

main :: IO ()
main = shakeArgs shakeOptions{shakeFiles="_build"} $ do
  action $ do
    liftIO $ Directory.createDirectoryIfMissing True "./book-src"

  phony "process" $ do
    putInfo "[+] Processing files…"
    void $ Map.traverseWithKey (\moduleDir bookDir -> do
      liftIO $ Directory.createDirectoryIfMissing True ("./book-src" </> bookDir)
      files <- getDirectoryFiles ("src/Book" </> moduleDir) ["//*.lhs"]
      liftIO $ print files
      forM_ files $ \f -> do
        liftIO $ LiterateX.transformFileToFile
          SourceFormat.LiterateHaskell
          (Renderer.defaultOptionsFor "haskell")
          ("src/Book" </> moduleDir </> f)
          (traceId $ toMarkdownFile f bookDir))
      chapters

chapters :: Map FilePath FilePath
chapters = Map.fromList
  [ ("01About", "01-about")
  , ("02GottaGoFast", "02-gotta_go_fast")
  ]

toMarkdownFile :: FilePath -> FilePath -> FilePath
toMarkdownFile f bookChapter =
  f
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
