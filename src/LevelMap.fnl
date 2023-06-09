(local LevelMap (util.class))

(fn LevelMap.constructor [levelname]
  (let [map (require (.. "levels/" levelname "/map"))]
    {: map
     :tile-gfx (love.graphics.newImage (.. "levels/" levelname "/tiles.png"))
     :tile-map {}
     :highlight-map {}
     :tile-masks {}
     :scroll (Vec2 80 0)}))

(fn LevelMap.instantiate [self]
  ;; copy tables to Vec3 where applicable
  (set self.map.size (Vec3 (unpack self.map.size)))
  (each [_i obj (ipairs self.map.objects)]
    (set obj.pos (Vec3 (unpack obj.pos)))
    (set obj.size (Vec3 (unpack obj.size))))
  ;; render objects into tile-map and color-map
  (each [_i obj-data (ipairs self.map.objects)]
        (self:render-object obj-data)))

(fn LevelMap.draw-map [self]
  (for [i 0 (length self.layers)]
    (self:draw-layer i)))

(fn LevelMap.draw-layer [self layer-index]
  (for [z 0 (- self.map.size.z 1)]
    (for [x 0 (- self.map.size.x 1)]
      (self:draw-tile (Vec3 x layer-index z)))))

(fn LevelMap.draw-tile [self pos]
  (let [tile-index (self:tile-index pos)
        tile (?. self.tile-map tile-index :tile)
        color (or (. self.highlight-map tile-index)
                  (?. self.tile-map tile-index :color))
        screen-pos (- (pos:project-to-screen) (Vec2 16 0))]
    (when (= tile 1)
      (love.graphics.setColor (if color (unpack color) [1 1 1 1]))
      (love.graphics.draw self.tile-gfx screen-pos.x screen-pos.y))))

(fn LevelMap.within-map-bounds? [self point]
  (point:within (Vec3 0 0 0) self.map.size))

(fn LevelMap.tile-index [self {: x : y : z}]
  ;; given an integer tile position point, give the index into self.tile-map
  (+
   x
   (* self.map.size.x z)
   (* self.map.size.x self.map.size.z y)))

(fn LevelMap.render-object [self obj]
  ;; turn an object into tiles
  ;; delete pre-existing object
  (if (. self.tile-masks obj)
    (self:delete-object obj))
  ;; render object
  (let [renderer (require (.. "objects/" obj.type))]
    (tset self.tile-masks obj [])
    (renderer.render {:set-tile
                      (fn [pos ...]
                        (when (self:within-map-bounds? pos)
                          (tset (. self.tile-masks obj) (self:tile-index pos) true)
                          (self:set-tile obj pos ...)))}
                obj)
    (if (?. _G.DEBUG :render-object)
        (_G.DEBUG.info "Rendered " obj))))

(fn LevelMap.set-tile [self obj pos value props]
  ;; @obj: the source data table for the object which is setting the tile.
  ;; @value: which tile to set.
  (if (self:within-map-bounds? pos)
      (do
        (let [tile-index (self:tile-index pos)
              prev-tile (. self.tile-map tile-index)]
          (tset self.tile-map tile-index
                {:object obj
                 :tile value
                 :color (. self :map :colormap props.color)
                 : prev-tile})))
      (when (?. DEBUG :tiles)
        (DEBUG.warn-with-traceback "Attempt to set out of bounds tile" pos value))))

(fn LevelMap.get-tile [self pos]
  ;; get a tile at pos
  (and (self:within-map-bounds? pos)
    (let [index (self:tile-index pos)]
      (. self.tile-map index))))

(fn LevelMap.highlight-object-at [self pos color]
  ;; highlight the object which contains a tile at pos
  ;; call with nothing to highlight nothing
   (let [tile (and pos (self:get-tile pos))
         object (and tile (. tile :object))]
     (self:highlight-object object color)
     pos))

(fn LevelMap.highlight-object [self obj color]
  ;; highlight an object given its input data
  (set self.highlight-map [])
  (when obj
    (set self.highlight-map
         (collect [i _ (pairs (. self.tile-masks obj))] (values i color)))))

(fn LevelMap.delete-object-at [self pos]
  (when pos
    (let [tile (self:get-tile pos)]
      (if tile
       (self:delete-object tile.object)
       (when (?. DEBUG :tiles)
         (DEBUG.warn-with-traceback "Attempt to delete OOB tile" pos))))))

(fn LevelMap.delete-object [self obj]
  (each [index _ (pairs (. self.tile-masks obj))]
    (let [tile (. self.tile-map index)]
      (tset self.tile-map index (self:tile-without-object tile obj))))
  (tset self.tile-masks obj nil))

(fn LevelMap.tile-without-object [self tile obj]
  ;; Remove all references to a given object from a tile, and return the
  ;; modified tile.
  (if (= tile.object obj)
      tile.prev-tile
      (do
        (set tile.prev-tile (self:tile-without-object tile.prev-tile obj))
        tile)))

(fn LevelMap.get-tile-position-at [self point]
  (local dummy-pos (Vec3 -1 -1 -1))
  (var closest-tile-pos dummy-pos)
  (fn closest-tile-in-axis [axis offset]
    (for [i 0 (. self.map.size axis)]
      (let [intersect-fn (. point (.. "locate-mouse-with-" axis))
            tile-pos-frac (intersect-fn point i)
            tile-pos (+ offset (tile-pos-frac:map math.floor))
            tile (self:get-tile tile-pos)]
        (if (and tile (tile-pos:is-closer-to-mouse closest-tile-pos))
            (set closest-tile-pos tile-pos)))))
  (closest-tile-in-axis :x (Vec3 -1 0 0))
  (closest-tile-in-axis :y 0)
  (closest-tile-in-axis :z (Vec3 0 0 -1))
  (if (= closest-tile-pos dummy-pos)
      false
      closest-tile-pos))

LevelMap
