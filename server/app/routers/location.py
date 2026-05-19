"""Location Services — Google Maps Places Autocomplete & Geocoding proxy.

Environment:
  GOOGLE_MAPS_API_KEY  (required) — Google Maps API key with Places & Geocoding enabled.
"""

import os
import logging
from typing import Optional

import aiohttp
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

logger = logging.getLogger("location")

router = APIRouter(tags=["location"])

GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "")
PLACES_BASE = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
GEOCODE_BASE = "https://maps.googleapis.com/maps/api/geocode/json"
NEARBY_BASE = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
TEXTSEARCH_BASE = "https://maps.googleapis.com/maps/api/place/textsearch/json"


# ── Models ───────────────────────────────────────────────────────────────────


class LocationSearchRequest(BaseModel):
    query: str
    session_token: Optional[str] = None


class LocationGeocodeRequest(BaseModel):
    address: str


class LocationReverseGeocodeRequest(BaseModel):
    lat: float
    lng: float


class LocationResult(BaseModel):
    place_id: str
    description: str
    structured_formatting: Optional[dict] = None


class LocationSearchResponse(BaseModel):
    predictions: list[LocationResult]
    status: str


class GeocodeResult(BaseModel):
    formatted_address: str
    lat: float
    lng: float
    place_id: str


class NearbySearchRequest(BaseModel):
    lat: float
    lng: float
    radius: int = 1500  # meters (1.5km default)
    type: str = "restaurant"  # restaurant, hotel, spa, etc.
    keyword: Optional[str] = None


class NearbyPlaceResult(BaseModel):
    place_id: str
    name: str
    address: str
    lat: float
    lng: float
    rating: Optional[float] = None
    types: list[str] = []
    photo_ref: Optional[str] = None
    open_now: Optional[bool] = None
    price_level: Optional[int] = None


class NearbySearchResponse(BaseModel):
    results: list[NearbyPlaceResult]
    status: str
    next_page_token: Optional[str] = None


# ── Helpers ──────────────────────────────────────────────────────────────────


async def _places_autocomplete(query: str, session_token: str | None = None) -> dict:
    """Call Google Places Autocomplete API."""
    if not GOOGLE_MAPS_API_KEY:
        raise HTTPException(500, "GOOGLE_MAPS_API_KEY is not configured")

    params = {
        "input": query,
        "key": GOOGLE_MAPS_API_KEY,
        "language": "en",
        "region": "kr",
        "components": "country:kr",
    }
    if session_token:
        params["sessiontoken"] = session_token

    async with aiohttp.ClientSession() as session:
        async with session.get(PLACES_BASE, params=params) as resp:
            if resp.status != 200:
                raise HTTPException(502, f"Places API error: {resp.status}")
            return await resp.json()


async def _geocode(address: str) -> dict:
    """Call Google Geocoding API (address → lat/lng)."""
    if not GOOGLE_MAPS_API_KEY:
        raise HTTPException(500, "GOOGLE_MAPS_API_KEY is not configured")

    params = {
        "address": address,
        "key": GOOGLE_MAPS_API_KEY,
        "language": "en",
    }

    async with aiohttp.ClientSession() as session:
        async with session.get(GEOCODE_BASE, params=params) as resp:
            if resp.status != 200:
                raise HTTPException(502, f"Geocoding API error: {resp.status}")
            return await resp.json()


async def _reverse_geocode(lat: float, lng: float) -> dict:
    """Call Google Geocoding API (lat/lng → address)."""
    if not GOOGLE_MAPS_API_KEY:
        raise HTTPException(500, "GOOGLE_MAPS_API_KEY is not configured")

    params = {
        "latlng": f"{lat},{lng}",
        "key": GOOGLE_MAPS_API_KEY,
        "language": "en",
    }

    async with aiohttp.ClientSession() as session:
        async with session.get(GEOCODE_BASE, params=params) as resp:
            if resp.status != 200:
                raise HTTPException(502, f"Reverse geocode error: {resp.status}")
            return await resp.json()


# ── Endpoints ────────────────────────────────────────────────────────────────


@router.post("/api/location/search", response_model=LocationSearchResponse)
async def search_location(req: LocationSearchRequest):
    """Google Places Autocomplete — search addresses/places by query."""
    data = await _places_autocomplete(req.query, req.session_token)

    predictions = [
        LocationResult(
            place_id=p["place_id"],
            description=p["description"],
            structured_formatting=p.get("structured_formatting"),
        )
        for p in data.get("predictions", [])
    ]

    return LocationSearchResponse(
        predictions=predictions,
        status=data.get("status", "ERROR"),
    )


@router.post("/api/location/geocode", response_model=GeocodeResult)
async def geocode_address(req: LocationGeocodeRequest):
    """Convert an address string to lat/lng coordinates."""
    data = await _geocode(req.address)

    if data.get("status") != "OK" or not data.get("results"):
        raise HTTPException(404, f"Address not found: {req.address}")

    result = data["results"][0]
    loc = result["geometry"]["location"]

    return GeocodeResult(
        formatted_address=result["formatted_address"],
        lat=loc["lat"],
        lng=loc["lng"],
        place_id=result["place_id"],
    )


@router.post("/api/location/reverse-geocode", response_model=GeocodeResult)
async def reverse_geocode(req: LocationReverseGeocodeRequest):
    """Convert lat/lng coordinates to a formatted address."""
    data = await _reverse_geocode(req.lat, req.lng)

    if data.get("status") != "OK" or not data.get("results"):
        raise HTTPException(404, f"Coordinates not found: {req.lat}, {req.lng}")

    result = data["results"][0]
    loc = result["geometry"]["location"]

    return GeocodeResult(
        formatted_address=result["formatted_address"],
        lat=loc["lat"],
        lng=loc["lng"],
        place_id=result["place_id"],
    )


@router.post("/api/location/nearby", response_model=NearbySearchResponse)
async def nearby_search(req: NearbySearchRequest):
    """Google Places Nearby Search — find places within a radius.

    Types: restaurant, hotel, spa, cafe, bar, hospital, gym, etc.
    See: https://developers.google.com/maps/documentation/places/web-service/supported_types
    """
    if not GOOGLE_MAPS_API_KEY:
        raise HTTPException(500, "GOOGLE_MAPS_API_KEY is not configured")

    params = {
        "location": f"{req.lat},{req.lng}",
        "radius": req.radius,
        "key": GOOGLE_MAPS_API_KEY,
        "language": "en",
    }
    if req.type:
        params["type"] = req.type
    if req.keyword:
        params["keyword"] = req.keyword

    async with aiohttp.ClientSession() as session:
        async with session.get(NEARBY_BASE, params=params) as resp:
            if resp.status != 200:
                raise HTTPException(502, f"Nearby Search API error: {resp.status}")
            data = await resp.json()

    results = []
    for p in data.get("results", []):
        loc = p.get("geometry", {}).get("location", {})
        photo = p.get("photos", [])
        results.append(NearbyPlaceResult(
            place_id=p["place_id"],
            name=p.get("name", ""),
            address=p.get("vicinity", ""),
            lat=loc.get("lat", 0.0),
            lng=loc.get("lng", 0.0),
            rating=p.get("rating"),
            types=p.get("types", []),
            photo_ref=photo[0]["photo_reference"] if photo else None,
            open_now=p.get("opening_hours", {}).get("open_now"),
            price_level=p.get("price_level"),
        ))

    return NearbySearchResponse(
        results=results,
        status=data.get("status", "ERROR"),
        next_page_token=data.get("next_page_token"),
    )


@router.post("/api/location/textsearch")
async def text_search(query: str, lat: float | None = None, lng: float | None = None):
    """Google Places Text Search — find places by text query with optional location bias."""
    if not GOOGLE_MAPS_API_KEY:
        raise HTTPException(500, "GOOGLE_MAPS_API_KEY is not configured")

    params = {
        "query": query,
        "key": GOOGLE_MAPS_API_KEY,
        "language": "en",
    }
    if lat is not None and lng is not None:
        params["location"] = f"{lat},{lng}"
        params["radius"] = 5000

    async with aiohttp.ClientSession() as session:
        async with session.get(TEXTSEARCH_BASE, params=params) as resp:
            if resp.status != 200:
                raise HTTPException(502, f"Text Search API error: {resp.status}")
            return await resp.json()


@router.get("/api/location/health")
async def location_health():
    """Check if Google Maps API key is configured."""
    return {
        "configured": bool(GOOGLE_MAPS_API_KEY),
        "key_prefix": GOOGLE_MAPS_API_KEY[:8] + "..." if GOOGLE_MAPS_API_KEY else None,
    }


# Alias at /location/health for external health checks
@router.get("/location/health")
async def location_health_alias():
    """Alias for /api/location/health."""
    return {
        "configured": bool(GOOGLE_MAPS_API_KEY),
        "key_prefix": GOOGLE_MAPS_API_KEY[:8] + "..." if GOOGLE_MAPS_API_KEY else None,
    }
