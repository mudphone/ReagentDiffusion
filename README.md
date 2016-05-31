# Diffusion

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## WAT IS

* This is a diffustion experiment based on [Daniel Shiffman's lecture](https://www.youtube.com/watch?v=BV9ny785UNc).

## WAT DO

* mix phoenix.new diffusion
* cd diffusion
* lein new reagent-frontend diffusion
* mv diffusion cljs
* add Reagent app id to Phoenix template
* add Reagent dep for Phoenix CLJSJS
* remove all js from dev.exs live_reload spec
** keep only priv/static/js/app.js, to work with figwheel
*

## Development Mode

From: https://github.com/gadfly361/reagent-figwheel

### Start Cider from Emacs:

Put this in your Emacs config file:

```
(setq cider-cljs-lein-repl "(do (use 'figwheel-sidecar.repl-api) (start-figwheel!) (cljs-repl))")
```

Navigate to a clojurescript file and start a figwheel REPL with `cider-jack-in-clojurescript` or (`C-c M-J`)

### Run application:

```
lein clean
lein figwheel
```

Figwheel will automatically push cljs changes to the browser.

Wait a bit, then browse to [http://localhost:3449](http://localhost:3449).

## Production Build

Don't know if this works yet...
```
lein clean
lein cljsbuild once min
```
