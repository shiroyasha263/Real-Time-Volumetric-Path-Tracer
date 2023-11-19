#include <optix_device.h>
#include <sutil/vec_math.h>
#include "random.h"
#include "LaunchParams.h"

extern "C" __constant__ PhotonBeamParams optixLaunchParams;

//------------------------------------------------------------------------------
// closest hit and anyhit programs for radiance-type rays.
//
// Note eventually we will have to create one pair of those for each
// ray type and each geometry type we want to render; but this
// simple example doesn't use any actual geometries yet, so we only
// create a single, dummy, set of them (we do have to have at least
// one group of them to set up the SBT)
//------------------------------------------------------------------------------

extern "C" __global__ void __closesthit__radiance()
{ /*! for this simple example, this will remain empty */
}

extern "C" __global__ void __anyhit__radiance()
{ /*! for this simple example, this will remain empty */
}



//------------------------------------------------------------------------------
// miss program that gets called for any ray that did not have a
// valid intersection
//
// as with the anyhit/closest hit programs, in this example we only
// need to have _some_ dummy function to set up a valid SBT
// ------------------------------------------------------------------------------

extern "C" __global__ void __miss__radiance()
{ /*! for this simple example, this will remain empty */
}



//------------------------------------------------------------------------------
// ray gen program - the actual rendering happens in here
//------------------------------------------------------------------------------
extern "C" __global__ void __raygen__renderFrame()
{
    if (optixGetLaunchIndex().x == 0 &&
        optixGetLaunchIndex().y == 0) {
        // we could of course also have used optixGetLaunchDims to query
        // the launch size, but accessing the optixLaunchParams here
        // makes sure they're not getting optimized away (because
        // otherwise they'd not get used)
        printf("############################################\n");
        printf("Hello world from OptiX 7 raygen program!\n(within a %ix%i-sized launch)\n",
            optixLaunchParams.maxBeams, 1);
        printf("############################################\n");
    }
    
    // ------------------------------------------------------------------
    // for this example, produce a simple test pattern:
    // ------------------------------------------------------------------
    
    // compute a test pattern based on pixel ID
    const uint3 idx = optixGetLaunchIndex();

    unsigned int seed = tea<4>(idx.x, idx.y);
    float3 start = make_float3(rnd(seed) * 2.f - 1.f, rnd(seed) * 2.f - 1.f, rnd(seed) * 2.f - 1.f) / 10.f;
    float transmittance = 1.f;
    for (int i = 0; i < optixLaunchParams.maxBounce; i++) {
        optixLaunchParams.beams[idx.x * optixLaunchParams.maxBounce + i].transmittance = transmittance;
        optixLaunchParams.beams[idx.x * optixLaunchParams.maxBounce + i].start = start;
        float3 dir = 2.0f * make_float3(rnd(seed), rnd(seed), rnd(seed)) - 1.0f;
        dir = normalize(dir);
        float eta = rnd(seed);
        float t = (-1.0f * log(1 - eta)) / optixLaunchParams.materialProp;
        float3 end = start + t * dir;
        optixLaunchParams.beams[idx.x * optixLaunchParams.maxBounce + i].end = end;
        start = end;
        transmittance = transmittance * exp(-t * optixLaunchParams.materialProp);
    }
    // and write to frame buffer ...
}