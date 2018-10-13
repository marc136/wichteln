import './main.css';
import { Elm } from './Main.elm';
// import registerServiceWorker from './registerServiceWorker';

let flags = {}
flags.now = Date.now()

Elm.Main.init({
  node: document.getElementById('root'),
  flags
});

// registerServiceWorker();
