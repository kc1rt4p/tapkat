// Config
const defaultConnectTimeout = 30000;
const defaultReceiveTimeout = 30000;
const baseURL = 'https://api.cloud-next.com.au/';
const productCount = 10;

// Keys
const psk = 'lcp9321p';

const iOSGoogleMapsApiKey = 'AIzaSyBCyNgeJDA8_nwdGrPf5ecuIsVFRXSF0mQ';
const androidGoogleMapsApiKey = 'AIzaSyAH4fWM5IbEO0X-Txkm6HNsFAQ3KOfW20I';
const webGoogleMapsApiKey = 'AIzaSyAzPjfTTLzdfp-56tarHguvLXgdw7QAGkg';

enum ProductListType {
  reco,
  demand,
  user,
}

const List<String> productStatusList = [
  'available',
  'reserved',
  'completed',
];
