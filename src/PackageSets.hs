{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TupleSections     #-}

module PackageSets where

import           Data.Map       hiding (map)
import           Data.String
import           System.Process

import           Path

data PackageSet
  = PackageSet {
    cabalConfig :: [(String, String)]
  }
  | StackageConfigFile {
    cabalConfigUrl :: String,
    packages :: [String]
  }
  deriving (Show)

packageNames :: PackageSet -> [String]
packageNames (PackageSet cabalConfig) = map fst cabalConfig
packageNames (StackageConfigFile _ names) = names

writeCabalConfig :: Path Sandbox -> PackageSet -> IO ()
writeCabalConfig sandboxDir (PackageSet cabalConfig) = do
  writeFile (toPath $ getCabalConfig sandboxDir) $ unlines $
    "constraints:" :
    map (\ (package, version) -> "  " ++ package ++ " == " ++ version)
        cabalConfig
writeCabalConfig sandboxDir (StackageConfigFile url _) = do
  callCommand ("wget '" ++ url ++ "' -O " ++ toPath (getCabalConfig sandboxDir))


-- * package set definitions

getPackageSet :: PackageSetName -> Either String PackageSet
getPackageSet name = maybe
  (Left ("unknown package set: " ++ fromPackageSetName name))
  Right
  (Data.Map.lookup name packageSets)

packageSets :: Map PackageSetName PackageSet
packageSets = fromList $
  ("test", PackageSet [("tagged", "0.7")]) :
  map
    (\ version ->
      (fromString ("rc-" ++ showVersion version),
       StackageConfigFile
         ("http://www.stackage.org/snapshot/lts-" ++ showVersion version ++ "/cabal.config")
         stackagePackages))
    ltsVersions ++
  []

latest :: PackageSetName
latest = fromString ("rc-" ++ showVersion (maximum ltsVersions))

showVersion :: (Int, Int) -> String
showVersion (a, b) = show a ++ "." ++ show b

ltsVersions :: [(Int, Int)]
ltsVersions =
  map (1,) [1 .. 15]

stackagePackages :: [String]
stackagePackages =
  "aeson" :
  "base-compat" :
  "case-insensitive" :
  "cassava" :
  "cmdArgs" :
  "containers" :
  "deepseq" :
  "directory" :
  "directory-tree" :
  "either" :
  "enclosed-exceptions" :
  "errors" :
  "filepath" :
  "http-client" :
  "mime-mail" :
  "mtl" :
  "optparse-applicative" :
  "process" :
  "safe" :
  "silently" :
  "string-conversions" :
  "tagged" :
  "temporary" :
  "transformers" :
  "yaml" :
  "hspec" :
  []
