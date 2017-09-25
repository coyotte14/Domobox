<?php
/**
 * Optimized algorithm from http://www.codexworld.com
 *
 * @param float $latFrom
 * @param float $lonFrom
 * @param float $latTo
 * @param float $lonTo
 *
 * @return float [km]
 */
function codexworldGetDistanceOpt($latFrom, $lonFrom, $latTo, $lonTo)
{
    $rad = M_PI / 180;
    //Calculate distance from latitude and longitude
    $theta = $lonFrom - $lonTo;
    $dist = sin($latFrom * $rad) * sin($latTo * $rad) +  cos($latFrom * $rad) * cos($latTo * $rad) * cos($theta * $rad);

    return acos($dist) / $rad * 60 *  1.852;
}

if (isset($_GET['latFrom']) AND isset($_GET['lonFrom'])  AND isset($_GET['latTo']) AND isset($_GET['lonTo']) )
{
        echo round(codexworldGetDistanceOpt($_GET['latFrom'], $_GET['lonFrom'], $_GET['latTo'], $_GET['lonTo'], $_GET['unit']));
}

?>
