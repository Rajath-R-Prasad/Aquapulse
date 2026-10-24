import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import '@fontsource-variable/inter';
import 'leaflet/dist/leaflet.css';
import './index.css';
import { Providers } from './app/providers';

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <Providers />
  </StrictMode>,
);
