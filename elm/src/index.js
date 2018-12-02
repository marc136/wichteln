import './main.css'
import { Elm } from './Main.elm'
import './elm-pep.js'
// import registerServiceWorker from './registerServiceWorker'
import { Howl, Howler } from 'howler'

const sounds = {
  'lamp-click': new Howl({
    src: ['sounds/145804__joedeshon__pull-chain-switch-02.wav']
  })
}

let flags = {}
flags.now = Date.now()

const app = Elm.Main.init({
  node: document.getElementById('root'),
  flags
})

app.ports.participate.subscribe(data => {
  if (data.play) {
    const sound = sounds[data.play]
    if (typeof sound.play === 'function') {
      console.log(`Played sound "${data.play}"`)
      sound.play()
    } else {
      console.log(`Could not play sound "${data.play}"`)
    }
  } else {
    console.log('participate port', data)
  }
})

// registerServiceWorker()
