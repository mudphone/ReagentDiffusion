(ns diffusion.canvas
  (:require
   [clojure.string :as str]
   [reagent.core :as reagent :refer [atom]]))

(defonce grid (reagent/atom {}))

(defn draw-point
  ([ctx x y gray size]
   (set! (.-fillStyle ctx)
         (str "rgba(" gray ", " gray ", " gray ", 1.0)"))
   (.fillRect ctx x y size size))
  ([ctx x y gray]
   (draw-point ctx x y gray 1)))

(defn draw-grid
  "Draw grid which comes from Phoenix channel as:
   {\"x,y\" {:a a-val :b b-val} ...}"
  [ctx g]
  (doseq [[k cell] g]
    (let [{a "a" b "b"} cell
          [x y] (map #(js/parseInt % 10)
                     (str/split k (re-pattern ",")))
          gray (-> (Math/floor (* 255.0 (- a b)))
                   (max 0.0)
                   (min 255.0))]
      #_(if (and (= 0 (mod x 20)) (= 0 (mod y 20)))
        (.log js/console "gray: " gray " a: " a " b: " b " cell: " cell))
      (draw-point ctx x y gray)))
)

(defn draw-canvas-contents [ canvas ]
  (let [ctx (.getContext canvas "2d")
        w   (.-clientWidth canvas)
        h   (.-clientHeight canvas)]
    (.beginPath ctx)
    (.moveTo ctx 0 0)
    (.lineTo ctx w h)
    (.moveTo ctx w 0)
    (.lineTo ctx 0 h)
    (.stroke ctx)
    (draw-grid ctx @grid)))

(defn div-with-canvas [width height]
  (let [dom-node (reagent/atom nil)]
    (reagent/create-class
     {:component-did-update
      (fn [ this ]
        (draw-canvas-contents (.-firstChild @dom-node)))

      :component-did-mount
      (fn [ this ]
        (reset! dom-node (reagent/dom-node this)))

      :reagent-render
      (fn [ ]
        @grid ;; Trigger re-render on window resizes
        
        [:div.with-canvas
         ;; reagent-render is called before the compoment mounts, so
         ;; protect against the null dom-node that occurs on the first
         ;; render
         [:canvas (if-let [ node @dom-node ]
                    {:width width
                     :height height}
                    ;; {:width (.-clientWidth node)
                    ;;  :height (.-clientHeight node)}
                    )]])})))
