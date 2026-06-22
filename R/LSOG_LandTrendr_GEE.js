/**
 * LSOG_LandTrendr_GEE.js
 * Earth Engine (Code Editor) script: LandTrendr time-since-disturbance for the
 * LSOG continuity axis (A4). Higher-fidelity follow-up to the LCMS layer already
 * wired into phase 31. Produces year-of-greatest-disturbance, magnitude, and
 * duration over the four-state Northeast, exported as a multi-band GeoTIFF that
 * drops into phase31b in place of (or alongside) the LCMS year-of-disturbance.
 *
 * Run in the GEE Code Editor (code.earthengine.google.com) under Aaron's account.
 * After export completes in Drive, pull to Cardinal and point phase31b's A4 at it:
 *   A4 passes if greatest-disturbance magnitude < threshold over the record
 *   (i.e., no stand-replacing or substantial partial disturbance detected).
 *
 * Method: annual growing-season Landsat 5/7/8/9 surface-reflectance medoid
 * composites -> NBR -> ee.Algorithms.TemporalSegmentation.LandTrendr -> greatest
 * disturbance mapping (eMapR / Kennedy et al. 2018 conventions).
 * NBR is multiplied by -1 so that vegetation LOSS is a positive spectral delta,
 * the orientation LandTrendr expects for disturbance detection.
 */

// ---------------------------------------------------------------------------
// 0. Area of interest. Default: four-state Northeast bounding box. Replace with
//    your UT polygon / state boundaries asset for a tighter clip.
// ---------------------------------------------------------------------------
var aoi = ee.Geometry.Rectangle([-79.85, 40.45, -66.80, 47.60]); // ME, NH, VT, NY
Map.centerObject(aoi, 6);

var startYear = 1985;
var endYear   = 2023;
var startDay  = '06-20';   // growing-season window for the annual composite
var endDay    = '09-10';

// ---------------------------------------------------------------------------
// 1. Annual cloud-masked Landsat surface-reflectance NBR composites.
//    Harmonized C2 L2 across TM/ETM+/OLI; simple QA_PIXEL cloud/shadow mask.
// ---------------------------------------------------------------------------
function maskL2sr(img) {
  var qa = img.select('QA_PIXEL');
  var cloud  = qa.bitwiseAnd(1 << 3).neq(0);
  var shadow = qa.bitwiseAnd(1 << 4).neq(0);
  var mask = cloud.or(shadow).not();
  // scale optical bands to reflectance
  var opt = img.select(['SR_B.']).multiply(0.0000275).add(-0.2);
  return img.addBands(opt, null, true).updateMask(mask);
}
// band aliases per sensor so NBR uses NIR + SWIR2 consistently
function renameOLI(img){ return img.select(['SR_B5','SR_B7','QA_PIXEL'],['NIR','SWIR2','QA_PIXEL']); }
function renameTM (img){ return img.select(['SR_B4','SR_B7','QA_PIXEL'],['NIR','SWIR2','QA_PIXEL']); }

function nbrCollection(year) {
  var s = ee.Date.fromYMD(year, 1, 1).format('YYYY').cat('-').cat(startDay);
  var e = ee.Date.fromYMD(year, 1, 1).format('YYYY').cat('-').cat(endDay);
  var l9 = ee.ImageCollection('LANDSAT/LC09/C02/T1_L2').map(maskL2sr).map(renameOLI);
  var l8 = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2').map(maskL2sr).map(renameOLI);
  var l7 = ee.ImageCollection('LANDSAT/LE07/C02/T1_L2').map(maskL2sr).map(renameTM);
  var l5 = ee.ImageCollection('LANDSAT/LT05/C02/T1_L2').map(maskL2sr).map(renameTM);
  var col = l9.merge(l8).merge(l7).merge(l5).filterBounds(aoi).filterDate(s, e);
  // NBR = (NIR - SWIR2)/(NIR + SWIR2); * -1000 so LOSS is positive (LandTrendr convention)
  var nbr = col.map(function(img){
    var v = img.normalizedDifference(['NIR','SWIR2']).rename('NBR').multiply(-1000);
    return v.set('year', year);
  });
  return nbr;
}

var annualNBR = ee.ImageCollection.fromImages(
  ee.List.sequence(startYear, endYear).map(function(y){
    y = ee.Number(y);
    var med = nbrCollection(y).median().toShort();
    return med.set('system:time_start', ee.Date.fromYMD(y, 8, 1).millis()).set('year', y);
  })
);

// ---------------------------------------------------------------------------
// 2. LandTrendr temporal segmentation on the annual NBR series.
// ---------------------------------------------------------------------------
var lt = ee.Algorithms.TemporalSegmentation.LandTrendr({
  timeSeries: annualNBR,
  maxSegments: 8,
  spikeThreshold: 0.9,
  vertexCountOvershoot: 3,
  preventOneYearRecovery: true,
  recoveryThreshold: 0.25,
  pvalThreshold: 0.05,
  bestModelProportion: 0.75,
  minObservationsNeeded: 6
});

// ---------------------------------------------------------------------------
// 3. Greatest-disturbance mapping (year, magnitude, duration).
//    Standard eMapR change-extraction on the LandTrendr vertex array.
// ---------------------------------------------------------------------------
function extractGreatestDisturbance(ltResult) {
  var v = ltResult.select('LandTrendr');         // [4 x N] vertex array
  var vertexMask = v.arraySlice(0, 3, 4);        // isVertex row
  var vertices   = v.arrayMask(vertexMask);
  var left  = vertices.arraySlice(1, 0, -1);
  var right = vertices.arraySlice(1, 1, null);
  var startYr  = left.arraySlice(0, 0, 1);
  var endYr    = right.arraySlice(0, 0, 1);
  var startVal = left.arraySlice(0, 2, 3);
  var endVal   = right.arraySlice(0, 2, 3);
  var dur = endYr.subtract(startYr);
  var mag = endVal.subtract(startVal);           // positive = NBR loss = disturbance
  var seg = ee.Image.cat([startYr.add(1), mag, dur]).toArray(0); // [yr, mag, dur]
  // keep only disturbance segments (mag > 100, i.e., NBR drop), pick the largest mag
  var distMask = mag.gt(100);
  var segMasked = seg.arrayMask(distMask.arrayCat(distMask, 0).arrayCat(distMask, 0));
  var magOnly = mag.arrayMask(distMask);
  var idx = magOnly.abs().arrayArgmax().arrayFlatten([['max']]);
  var pick = segMasked.arraySlice(1, ee.Image(idx), ee.Image(idx).add(1));
  var yod = pick.arraySlice(0, 0, 1).arrayProject([1]).arrayFlatten([['yod']]);
  var magO = pick.arraySlice(0, 1, 2).arrayProject([1]).arrayFlatten([['mag']]);
  var durO = pick.arraySlice(0, 2, 3).arrayProject([1]).arrayFlatten([['dur']]);
  return yod.addBands(magO).addBands(durO).toShort();
}

var disturbance = extractGreatestDisturbance(lt).clip(aoi);
// year-of-greatest-disturbance (0 where none), magnitude (NBR*1000 units), duration (yr)
var tsd = ee.Image(endYear).subtract(disturbance.select('yod')).rename('tsd')
            .updateMask(disturbance.select('yod').gt(0));

// quick look
Map.addLayer(disturbance.select('yod').selfMask(),
  {min:1985, max:2023, palette:['ffffcc','c2e699','78c679','31a354','006837']}, 'year of greatest disturbance');
Map.addLayer(tsd, {min:0, max:38, palette:['006837','78c679','ffffcc','fdae61','d7191c']}, 'time since disturbance');

// ---------------------------------------------------------------------------
// 4. Export. yod/mag/dur as a 3-band GeoTIFF at 30 m to Drive.
//    Pull to Cardinal, then in phase31b set A4 = no segment with mag >= MAG_THRESH
//    over the record (start with MAG_THRESH ~ 200 NBR*1000; tune against field).
// ---------------------------------------------------------------------------
Export.image.toDrive({
  image: disturbance.select(['yod','mag','dur']).unmask(0),
  description: 'LSOG_LandTrendr_NBR_greatestDist_NE_1985_2023',
  folder: 'GEE_LSOG',
  region: aoi,
  scale: 30,
  crs: 'EPSG:5070',
  maxPixels: 1e13
});

print('LandTrendr disturbance image (bands yod, mag, dur):', disturbance);
print('Run the Export task from the Tasks tab. Then on Cardinal, swap into phase31b A4:',
      'A4 passes where yod==0 OR mag < MAG_THRESH (no stand-replacing/substantial partial loss).');
