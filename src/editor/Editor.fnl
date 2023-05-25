(var Editor (util.class))

(local UI (require :src.lib.UI))
(local LevelMap (require :src.LevelMap))

(fn Editor.constructor [{: screen-size} levelname]
  (love.keyboard.setKeyRepeat true)
  {:level (LevelMap levelname)
   :add-object {:type :cube :pos (Vec3 0 0 0) :size (Vec3 1 1 1) :color "green"}
   :layer-index 1
   :camera {:center (Vec2 100 0) :zoom 4} ;; boundaries of camera
   :scroll-rate 8
   :panning false
   :mode {}})

(fn Editor.instantiate [self]
  (set self.UI
       (UI
        [:node
         {:position (Vec2 0 0)
          :size (Vec2 0 0)}
         [
          [:node
           {:position (Vec2 0 0)
            :size (Vec2 40 80)
            :display [:image "src/editor/layerselect.png"]}
           [
            [:button
             {:position (Vec2 0 16)
              :size (Vec2 40 32)
              :onclick #(self:set-layer-relative -1)}]
            [:button
             {:position (Vec2 0 48)
              :size (Vec2 40 32)
              :onclick #(self:set-layer-relative 1)}]]]
          [:button
           {:position (Vec2 40 0)
            :size (Vec2 64 64)
            :display [:image-quad "src/editor/delete.png" 0 0 32 32]
            :watch [self :mode]
            :update
            (fn [elem]
            ;; increase the x of the image quad
             (tset (. elem 2 :display) 3
                   (case self.mode
                     {:type :delete :many false} 32
                     {:type :delete :many true} 64
                     _ 0)))
            :onclick #(self:next-delete-mode)}]
          [:button
           {:position (Vec2 104 0)
            :size (Vec2 64 64)
            :display [:image-quad "src/editor/add.png" 0 0 32 32]
            :watch [self :mode]
            :update
            (fn [elem]
            ;; increase the x of the image quad
             (tset (. elem 2 :display) 3
                   (case self.mode
                     {:type :add} 32
                     _ 0)))
            :onclick #(self:toggle-add-mode)}]]]))
  (set self.event-handlers [self.UI self]))

(fn Editor.destructor []
  (love.keyboard.setKeyRepeat false))

;; cycle thru delete modes
(fn Editor.next-delete-mode [self]
  (set self.mode
       (case self.mode
         {:type :delete :many false} {:type :delete :many true}
         {:type :delete :many true} {}
         _ {:type :delete :many false})))

(fn Editor.toggle-add-mode [self]
  (set self.mode
       (case self.mode
         {:type :add}
         (do
           (if self.mode.object-added
               (self.level:delete-object self.add-object))
           {})
         _ {:type :add})))

(fn Editor.get-transform [self]
  (util.transform-from-list
   [:translate (/ (util.screen-size) 2)]
   [:scale self.camera.zoom]
   [:translate (- self.camera.center)]))

;; Perform function f with the boundaries of the current camera
(fn Editor.with-camera [self f]
  (util.with-transform (self:get-transform) f))

;; Scales the mouse position in accordance with zoom/scroll
(fn Editor.mouse-to-ingame-pos [self point]
  (let [tform (self:get-transform)]
    (Vec2 (tform:inverseTransformPoint point.x point.y))))

(fn Editor.get-mouse-tile [self pos]
  (self.level:get-tile-position-at (self:mouse-to-ingame-pos pos)))

(fn Editor.adjust-zoom [self offset center-point]
  (let [next-zoom (+ self.camera.zoom offset)]
   (if (and (>= next-zoom 0.5) (<= next-zoom 8))
    (do
      (set self.camera.zoom next-zoom)
      (when center-point
        (set self.camera.center
           (util.lume.lerp self.camera.center center-point 0.5)))))))

(fn Editor.set-layer [self layer]
  (set self.layer-index (util.clamp layer 0 self.level.map.size.y)))

(fn Editor.set-layer-relative [self amount]
  (self:set-layer (+ self.layer-index amount)))

(set Editor.key-binds
  (let [set-scroll
        (fn [self offset is-shifted]
          (set self.camera.center
               (+ self.camera.center
                  (* offset
                     self.scroll-rate
                     (if is-shifted 8 1)))))]
    {:w (fn [self] (self:set-layer-relative -1))
     :s (fn [self] (self:set-layer-relative 1))
     "=" #(Editor.adjust-zoom $1 1)
     "-" #(Editor.adjust-zoom $1 -1)
     :a #(Editor.toggle-add-mode $1)
     :x #(Editor.next-delete-mode $1)
     :up (fn [self modifiers] (set-scroll self (Vec2 0 -1) modifiers.shift))
     :down (fn [self modifiers] (set-scroll self (Vec2 0 1) modifiers.shift))
     :left (fn [self modifiers] (set-scroll self (Vec2 -1 0) modifiers.shift))
     :right (fn [self modifiers] (set-scroll self (Vec2 1 0) modifiers.shift))}))

(fn Editor.draw [self]
  ;; draw map
  (self:draw-map util.screen-size)
  (self.UI:draw))

(fn Editor.draw-map [self]
  (for [i self.level.map.size.y 0 -1]
    (when (and (= self.mode.type :add) (= i self.layer-index))
      (self:draw-grid i))
    (self:with-camera #(self.level:draw-layer i))))

(fn Editor.draw-grid [self layer]
  (self:with-camera
   #(util.with-color-rgba 1 1 1 0.1
     #(do
       (for [x 0 self.level.map.size.x]
         (self:draw-grid-line layer x :x))
       (for [z 0 self.level.map.size.z]
         (self:draw-grid-line layer z :z)))))
  (util.with-color-rgba 0 0 1 0.1
    (let [(x y) (love.window.getMode)]
      #(love.graphics.rectangle :fill 0 0 x y))))

;; draw a single grid line (assumes that color and transform have been set
;; already)
(fn Editor.draw-grid-line [self layer i axis]
  (let [opposite (if (= axis :x) :z :x)
        mirror (if (= axis :z) (Vec2 -1 1) (Vec2 1 1))
        start3 (Vec3 i layer 0)
        end3 (Vec3 i layer (. self.level.map.size opposite))
        start (* mirror (start3:project-to-screen))
        end (* mirror (end3:project-to-screen))]
     (love.graphics.setLineWidth (/ 1 self.camera.zoom))
     (love.graphics.line start.x start.y end.x end.y)
     (love.graphics.setLineWidth 1)))

(fn Editor.update [self])

(fn Editor.keypressed [self scancode modifiers]
  (when (. self.key-binds scancode) ((. self.key-binds scancode) self modifiers)))

(fn Editor.mousepressed [self x y button]
  (if
   (= button 3)
   (set self.panning {:last-pos (Vec2 x y)})

   (= self.mode.type :delete)
   (do
     (self.level:delete-object-at (self:get-mouse-tile (Vec2 x y)))
     (if (not self.mode.many)
         (set self.mode {})))

   (= self.mode.type :add)
   (do
     (self.level:render-object (util.deep-copy self.add-object))
     (if (?. _G.DEBUG :editor-add-object)
         (_G.DEBUG.info "Added " self.add-object)))))

(fn Editor.mousereleased [self x y]
  (if self.panning (set self.panning false)))

(fn Editor.highlight-object-xy [self x y color]
  (local found-object-pos
         (self.level:highlight-object-at (self:get-mouse-tile (Vec2 x y)) color))
  (if (and found-object-pos (?. _G.DEBUG :editor-mouse-select))
      (_G.DEBUG.info "Highlight Tile: " (self.level:get-tile found-object-pos))))

(fn Editor.mousemoved [self x y]
  (if self.panning
    (do
      (set self.camera.center (- self.camera.center
                                (/
                                 (- (Vec2 x y) self.panning.last-pos)
                                 self.camera.zoom)))
      (set self.panning.last-pos (Vec2 x y)))
    (case self.mode.type
      nil
      (self:highlight-object-xy x y [0 1 1])
      :delete
      (self:highlight-object-xy x y [1 0 0])
      :add
      (let [ingame-pos (self:mouse-to-ingame-pos (Vec2 x y))
            layer-pos (ingame-pos:locate-mouse-with-y self.layer-index)
            tile-pos (layer-pos:map math.floor)]
       (when self.mode.object-added
         (self.level:delete-object self.add-object))
       (set self.add-object.pos tile-pos)
       (self.level:render-object self.add-object)
       (set self.mode.object-added true)))))

(fn Editor.wheelmoved [self x y]
  (let [mousepos (Vec2 (love.mouse.getPosition))]
    (self:adjust-zoom y (self:mouse-to-ingame-pos mousepos))))

Editor