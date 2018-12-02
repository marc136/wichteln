import './main.css'
import './elm-pep.js'
import { Howl, Howler } from 'howler'
import { Elm } from './Main.elm'
import registerServiceWorker from './registerServiceWorker'

const sounds = {
  'lamp-click': new Howl({
    src: ['sounds/145804__joedeshon__pull-chain-switch-02.wav']
  })
}


const items = [ "One", "Two", "Three", "Four" ]


const app = Elm.Main.init({
  flags: {
    random: items[Math.floor(Math.random() * items.length)],
    participants: items
  }
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

registerServiceWorker()
