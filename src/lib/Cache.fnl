(local Cache (util.class))

(fn Cache.constructor [type]
  (util.union
   {:cache {}}
   (case type
     :image {:loader love.graphics.newImage
             :pathgen (fn [x] x)}
     :quad {:loader (fn [image x y w h]
                      (love.graphics.newQuad x y w h image))
            :pathgen (fn [image x y w h]
                       (let [(iw ih) (image:getDimensions)]
                         (table.concat [x y w h iw ih] "-")))})))

(fn Cache.load [self ...]
  (let [path (self.pathgen ...)]
    (or (. self.cache path)
        (do
          (tset self.cache path (self.loader ...))
          (. self.cache path)))))

Cache
