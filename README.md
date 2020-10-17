# Ray

Simple rendering engine (no ray-tracing pun intended).

## PBR demo

<img src="https://raw.githubusercontent.com/pxl-th/Ray.jl/master/res/pbr-simple-demo.png" width=460>

To run demo execute following command:

```bash
julia --project=. sandbox/pbr/sandbox3d.jl
```

## 2D demo

Self-contained [example](https://github.com/pxl-th/MPM) of different material-point-methods.

| Fluid simulation | Elasticity |
|:-:|:-:|
| [YouTube](https://www.youtube.com/watch?v=O8cXswg9xHw)  | [YouTube](https://www.youtube.com/watch?v=B2dO3poS5PA) |
|<img src="https://img.youtube.com/vi/O8cXswg9xHw/hqdefault.jpg" alt="Fluid simulation" width="200"/>|<img src="https://img.youtube.com/vi/B2dO3poS5PA/hqdefault.jpg" alt="Elasticity" width="200"/> |

## Examples

See [sandbox/](https://github.com/pxl-th/Ray.jl/tree/master/sandbox) directory for examples on how to use it.

## Precompile

To reduce startup time you can precompile necessary dependencies into `.dll` which you can use with `--sysimage` to replace default sysimage:

```bash
julia --project=. create-sysimage.jl
```
