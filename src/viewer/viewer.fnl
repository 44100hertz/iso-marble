(import-macros {: incf} "src/lib/macros")

(var map nil)
(var tile-gfx nil)

(fn load-level [name]
  (set map (require (.. "levels/" name "/map")))
  (set tile-gfx (love.graphics.newImage (.. "levels/" name "/tiles.png"))))

(fn iso-to-screen [x y z]
  (values (* 16 (- z x))
          (* 16 (+ y (/ (+ x z) 2)))))

(fn draw-layer [map index]
  (let [tiles (. map :layers index :tiles)]
    (for [z 0 (- map.zsize 1)]
      (for [x 1 map.xsize]
        (let [tile (. tiles (+ (* z map.zsize) x))
              (screen-x screen-y) (iso-to-screen x (- index 1) z)]
          (when (= tile 1) (love.graphics.draw tile-gfx screen-x screen-y)))))))

(fn draw-map [map] (for [i (length map.layers) 1 -1] (draw-layer map i)))

(load-level :test)
{:draw (fn []
         (love.graphics.clear 0 0 0)
         (love.graphics.translate 80 0)
         (draw-map map))
 :update (fn [])
 :keypressed (fn [])}
