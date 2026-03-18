(ns sample.core)

(defn platform-name []
  #?(:clj "jvm" :cljs "js"))
