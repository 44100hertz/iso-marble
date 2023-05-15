(var Editor (util.class))

(import-macros {: ++} :src.lib.macros)
(local LevelMap (require :src.LevelMap))

(fn Editor.constructor [{: screen-size} levelname]
  (love.keyboard.setKeyRepeat true)
  {:map (LevelMap levelname)
   : screen-size
   :layer-index 1
   :layer-select-image (love.graphics.newImage "src/editor/layerselect.png")
   :camera {:center (Vec2 0 0) :zoom 1} ;; boundaries of camera
   :scroll-rate 8
   :drag-mode {}})

(fn Editor.destructor []
  (love.keyboard.setKeyRepeat false))

;; Perform function f with the boundaries of the current camera
(fn Editor.with-camera [self f]
  (util.with-transform
    [
     [:translate (/ self.screen-size (Vec2 2))]
     [:scale self.camera.zoom]
     [:translate self.camera.center]]
    f))

(fn Editor.set-layer [self layer]
  (set self.layer-index (util.clamp layer 1 (length self.map.layers))))

(fn Editor.set-layer-relative [self amount]
  (self:set-layer (+ self.layer-index amount)))

(set Editor.key-binds
  (let [set-scroll
        (fn [self offset is-shifted]
          (set self.camera.center (+ self.camera.center
                                     (* (Vec2 self.scroll-rate)
                                        offset
                                        (Vec2 (if is-shifted 8 1))))))
        set-zoom
        (fn [offset self]
          (set self.camera.zoom (util.clamp (+ self.camera.zoom offset) 0.125 2)))]

    {:q (fn [self] (self:set-layer-relative -1))
     :a (fn [self] (self:set-layer-relative 1))
     "=" (partial set-zoom 0.25)
     "-" (partial set-zoom -0.25)
     :up (fn [self modifiers] (set-scroll self (Vec2 0 1) modifiers.shift))
     :down (fn [self modifiers] (set-scroll self (Vec2 0 -1) modifiers.shift))
     :left (fn [self modifiers] (set-scroll self (Vec2 1 0) modifiers.shift))
     :right (fn [self modifiers] (set-scroll self (Vec2 -1 0) modifiers.shift))}))

(fn Editor.draw-map [self screen-size]
  (for [i (length self.map.layers) 1 -1]
    (when (= i self.layer-index)
      (util.with-color-rgba 1 0 0 0.2
        #(love.graphics.rectangle :fill 0 0 screen-size.x screen-size.y)))
    (self:with-camera #(self.map:draw-layer i))))

(fn Editor.draw [self {: screen-size}]
  ;; draw map
  (self:draw-map screen-size)
  ;; draw UI
;;  (love.graphics.print self.layer-index)
  (love.graphics.draw self.layer-select-image 0 0))

(fn Editor.update [self])

(fn Editor.keypressed [self scancode modifiers]
  (when (. self.key-binds scancode) ((. self.key-binds scancode) self modifiers)))

(fn Editor.mousepressed [self x y]
  (set self.drag-mode {:type :scroll :last-pos (Vec2 x y)}))

(fn Editor.mousereleased [self x y]
  (set self.drag-mode {}))

(fn Editor.mousemoved [self x y]
  (case self.drag-mode.type
    :scroll (do
              (set self.camera.center (+ self.camera.center
                                         (- (Vec2 x y) self.drag-mode.last-pos)))
              (set self.drag-mode.last-pos (Vec2 x y)))))

Editor
