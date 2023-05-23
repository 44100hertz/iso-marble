(local LevelMap (util.class))

(fn LevelMap.constructor [levelname]
  (let [map (require (.. "levels/" levelname "/map"))]
    {: map
     :tile-gfx (love.graphics.newImage (.. "levels/" levelname "/tiles.png"))
     :tile-map {}
     :highlight-map {}
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
  (for [i (length self.layers) 0 -1]
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

;; given an integer tile position point, give the index into self.tile-map
(fn LevelMap.tile-index [self {: x : y : z}]
  (+
   x
   (* self.map.size.x z)
   (* self.map.size.x self.map.size.z y)))

;; turn an object into tiles
(fn LevelMap.render-object [self obj]
  (let [renderer (require (.. "objects/" obj.type))]
    (set obj.tile-mask [])
    (renderer.render {:set-tile
                      (fn [pos ...]
                        (when (self:within-map-bounds? pos)
                          (tset obj.tile-mask (self:tile-index pos) true)
                          (self:set-tile obj pos ...)))}
                obj)
    (if (?. _G.DEBUG :render-object)
        (_G.DEBUG.info "Rendered " obj))))

;; @obj: the source data table for the object which is setting the tile.
;; @value: which tile to set.
(fn LevelMap.set-tile [self obj pos value props]
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

;; get a tile at pos
(fn LevelMap.get-tile [self pos]
  (and (self:within-map-bounds? pos)
    (let [index (self:tile-index pos)]
      (. self.tile-map index))))

;; highlight the object which contains a tile at pos
;; call with nothing to highlight nothing
(fn LevelMap.highlight-object-at [self pos color]
  (if pos
    (let [tile (self:get-tile pos)]
      (when tile
        (self:highlight-object tile.object color)
        pos))
    (set self.highlight-map [])))

;; highlight an object given its input data
(fn LevelMap.highlight-object [self obj color]
  (set self.highlight-map
       (collect [i _ (pairs obj.tile-mask)] (values i color))))

(fn LevelMap.delete-object-at [self pos]
  (when pos
    (let [tile (self:get-tile pos)]
      (if tile
       (self:delete-object tile.object)
       (when (?. DEBUG :tiles)
         (DEBUG.warn-with-traceback "Attempt to delete OOB tile" pos))))))

(fn LevelMap.delete-object [self obj]
  (each [index _ (pairs obj.tile-mask)]
    (let [tile (. self.tile-map index)]
      (tset self.tile-map index (self:tile-without-obj tile obj)))))

;; Remove all references to a given object from a tile, and return the modified
;; tile.
(fn LevelMap.tile-without-obj [self tile obj]
  (if (= tile.object obj)
      tile.prev-tile
      (do
        (set tile.prev-tile (self:tile-without-obj tile.prev-tile obj))
        tile)))

;; check an entire cube-shaped region based on a mouse position
(fn LevelMap.get-tile-position-at [self point]
    (var found-tile-pos false)
    (for [layer 0 self.map.size.y 1 &until found-tile-pos]
      (let [tile-at-plane-intersection
            (fn [intersect-fn offset]
              (let [intersect ((. point intersect-fn) point layer)
                    tile-pos (+ (intersect:map math.floor) offset)]
                (and (self:get-tile tile-pos) tile-pos)))]
        (set found-tile-pos
             (or
              (tile-at-plane-intersection :intersect-xz-plane (Vec3 0 0 0))
              (tile-at-plane-intersection :intersect-yz-plane (Vec3 -1 0 0))
              (tile-at-plane-intersection :intersect-xy-plane (Vec3 0 0 -1))))))
    found-tile-pos)

LevelMap
