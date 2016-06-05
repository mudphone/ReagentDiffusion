(ns diffusion.core
  (:require
   [diffusion.canvas :as canvas]
   [diffusion.channel :as ch]
   [reagent.core :as reagent :refer [atom]]
   [reagent.session :as session]
   [secretary.core :as secretary :include-macros true]))

(defonce counter (reagent/atom 0))
(defonce socket (ch/create-socket))
(defonce channel (reagent/atom nil))

;; -------------------------
;; Views

(defn home-page []
  [:div
   [:h2 "Counter: " @counter]
   [canvas/div-with-canvas 100 100]])

;; -------------------------
;; Initialize app

(defn mount-root []
  (reagent/render [home-page] (.getElementById js/document "app")))

(defn create-channel! []
  (let [chan (ch/create-join-query-channel! (ch/connect-socket! socket) "diffusion:1")]
    (-> chan 
        (.on "ping" #(let [{count "count"} (js->clj %1)]
                       (.log js/console "PING" count)
                       (reset! counter count))))
    (-> chan
        (.on "grid" #(let [{grid "grid"} (js->clj %1)]
                       (reset! canvas/grid grid))))
    chan))

(defn setup-channel! []
  (swap! channel
         #(if-not (nil? %1) %1 (create-channel!))))

(defn init! []
  (mount-root)
  (setup-channel!))
