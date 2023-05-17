(local Cache (util.class))

(fn Cache.constructor [type]
  (util.union
   {:cache {}}
   (case type
     :image {:loader love.graphics.newImage})))

(fn Cache.load [self path]
  (or (. self.cache path)
      (do
        (tset self.cache path (self.loader path))
        (. self.cache path))))

Cache
