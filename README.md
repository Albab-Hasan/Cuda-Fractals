# Beautiful CUDA Fractal Generator

Welcome to the most gorgeous fractal generator you'll ever use! This CUDA-powered beast creates stunning, high-resolution fractals that'll make your GPU sing and your eyes happy.

## What's This All About?

Ever wanted to generate mind-blowing fractals but got tired of waiting forever for CPU-based generators? This is your solution! We're talking about:

- **Lightning-fast generation** thanks to CUDA parallel processing
- **Smooth, rainbow gradients** that look like digital art
- **Multiple fractal types** because variety is the spice of life
- **High-resolution output** (1920x1080) perfect for wallpapers

## What You'll Get

Running this bad boy will generate 7 beautiful fractal images:

1. **Classic Mandelbrot** - The OG fractal that started it all
2. **Zoomed Mandelbrot** - Getting up close and personal with the details
3. **Julia Set #1** - Swirling patterns that look like cosmic storms
4. **Julia Set #2** - More Julia goodness with different parameters
5. **Julia Set #3** - Because three's a charm
6. **Burning Ship** - A twisted version that looks like... well, burning ships
7. **Deep Zoom Mandelbrot** - Going *really* deep into the rabbit hole          [Currently dosen't work]

## Getting Started

### What You Need

- NVIDIA GPU with CUDA support (pretty much any modern NVIDIA card works)
- CUDA toolkit installed on your system
- A C compiler (usually comes with CUDA)
- Some patience while your GPU does its magic

### Compilation

Dead simple:

```bash
nvcc -o fractal_generator fractal_generator.cu -lm
```

### Running It

Even simpler:

```bash
./fractal_generator
```

Sit back and watch as your terminal fills with progress messages and your directory fills with beautiful fractal art!

## Converting PPM to PNG (The Python Way)

The generator outputs PPM files because they're simple and fast to write. But let's be honest, nobody wants to deal with PPM files in 2025. Here's how to convert them to PNG using Python:

### Method 1: Using Pillow (Recommended)

First, install Pillow if you haven't already:

```bash
pip install Pillow
```

Then create this simple converter script:

```python
from PIL import Image; import glob; [Image.open(f).save(f.replace('.ppm','.png')) for f in glob.glob('*.ppm')]
```

## Customizing Your Fractals

Want to create your own fractal masterpieces? Here are some parameters you can tweak in the code:

- **WIDTH/HEIGHT**: Change the resolution (be careful, higher = slower)
- **MAX_ITER**: More iterations = finer detail (but slower generation)
- **Center coordinates**: Explore different regions of the fractals
- **Zoom levels**: Go deeper into the mathematical rabbit hole
- **Julia constants**: Try different values for completely different patterns

Some fun Julia set constants to try:
- `c = -0.8 + 0.156i` (looks like lightning)
- `c = -0.123 + 0.745i` (spiral galaxy vibes)
- `c = 0.3 + 0.5i` (abstract art territory)

## Troubleshooting

**"nvcc command not found"**: You need to install the CUDA toolkit first.

**"No CUDA-capable device"**: You need an NVIDIA GPU. Sorry, AMD folks!

**"Out of memory"**: Try reducing WIDTH and HEIGHT, or get a beefier GPU.

**"Images look weird"**: PPM files might not display correctly in some viewers. Convert to PNG first!

## Performance Tips

- The program is already pretty optimized, but you can experiment with different block sizes
- If you have multiple GPUs, you could modify the code to use them all
- For even higher resolutions, consider using double precision (but it'll be slower)

## Final Words

This fractal generator is designed to be both educational and practical. Feel free to dig into the code, modify it, and create your own mathematical art. The universe of fractals is infinite – have fun exploring it!

Happy fractal hunting!

---
