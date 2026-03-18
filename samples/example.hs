data PreviewSummary = PreviewSummary
  { fileName :: String
  , language :: String
  , truncated :: Bool
  }

statusLine :: PreviewSummary -> String
statusLine summary =
  fileName summary
    ++ " ["
    ++ language summary
    ++ "] "
    ++ if truncated summary then "truncated" else "ready"

buildSummary :: PreviewSummary
buildSummary =
  PreviewSummary
    { fileName = "stack.yaml"
    , language = "haskell"
    , truncated = False
    }

main :: IO ()
main = putStrLn (statusLine buildSummary)
