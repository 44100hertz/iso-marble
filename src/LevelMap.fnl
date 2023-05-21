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
        color (if (. self.highlight-map tile-index)
                  [1 0 0 1]
                  (?. self.tile-map tile-index :color))
        screen-pos (- (pos:project-to-screen) (Vec2 16 0))]
    (when (= tile 1)
      (love.graphics.setColor (if color (unpack color) (values 1 1 1 1)))
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
                        (tset obj.tile-mask (self:tile-index pos) true)
                        (self:set-tile obj pos ...))}
                obj)))

(fn LevelMap.delete-object [self obj-data])


;; @obj: the source data table for the object which is setting the tile.
;; @value: which tile to set.
(fn LevelMap.set-tile [self obj pos value props]
  (if (self:within-map-bounds? pos)
      (do
        (let [tile-index (self:tile-index pos)]
          (tset self.tile-map tile-index
                {:object obj
                 :tile value
                 :color (. self :map :colormap props.color)
                 ;; if overwriting tile, keep track of previous tile
                 :last-tile (. self.tile-map tile-index)})))
      (when (?. DEBUG :tiles)
        (DEBUG.warn-with-traceback "Attempt to set out of bounds tile" pos value))))

;; get a tile at pos
(fn LevelMap.get-tile [self pos]
  (and (self:within-map-bounds? pos)
    (let [index (self:tile-index pos)]
      (. self.tile-map index))))

;; highlight the object which contains a tile at pos
;; call with nothing to highlight nothing
(fn LevelMap.highlight-object-at [self pos]
  (if pos
    (let [tile (self:get-tile pos)]
      (set self.highlight-map tile.object.tile-mask))
    (set self.highlight-map [])))

;; highlight an object given its input data
(fn LevelMap.highlight-object [self obj]
  (set self.highlight-map [])
  (let [obj (require (.. "objects/" obj.type))
        set-tile (fn [pos]
                   (tset self.highlight-map (self:tile-index pos) true))]
    (obj.render {: set-tile}
                obj)))

(fn LevelMap.delete-object-at [self pos]
  (when pos
    (let [tile (self:get-tile pos)]
      (if tile
       (self:delete-object tile.object)
       (when (?. DEBUG :tiles)
         (DEBUG.warn-with-traceback "Attempt to delete OOB tile" pos))))))

(fn LevelMap.delete-object [self obj]
  (each [index tile (pairs obj.tile-mask)]
    ;; last-tile is typically nil, but if a tile has been overwritten, then
    ;; last-tile will be the tile that was overwritten. If the tile that was
    ;; overwritten doesn't belong to the object being deleted, then the tile
    ;; being deleted should be set to that tile instead of nullified. Otherwise,
    ;; it is already correct and the tile will not be modified.
    (let [last-tile (. self.tile-map index :last-tile)]
      (when (or (not last-tile) (~= last-tile.object obj))
        (tset self.tile-map index last-tile)))))

;; check an entire cube-shaped region based on a mouse position
(fn LevelMap.get-tile-position-at [self point]
    ;; cast a ray from the screen, check if it intersects with a tile at an
    ;; obscene number of points, to figure out what the mouse is pointing at
    (var found-tile-pos false)
    (for [layer 0 self.map.size.y (/ 1 128) &until found-tile-pos]
      (let [layer-pos (point:project-from-screen layer)
            tile-pos (layer-pos:map math.floor)]
        (set found-tile-pos
             (and (layer-pos:within tile-pos (Vec3 1 1 1))
                  (self:get-tile tile-pos)
                  tile-pos))))
    found-tile-pos)

LevelMap
