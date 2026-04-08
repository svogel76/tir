extends VoxelGeneratorScript
class_name TirTerrainGenerator

@export var noise_seed: int = 1337
@export_range(0.001, 0.2, 0.001) var base_frequency: float = 0.02
@export_range(0.001, 0.4, 0.001) var detail_frequency: float = 0.07
@export_range(1.0, 80.0, 0.5, "suffix:m") var base_amplitude: float = 7.0
@export_range(0.0, 30.0, 0.5, "suffix:m") var detail_amplitude: float = 1.5
@export_range(1.0, 80.0, 0.5, "suffix:m") var plateau_height: float = 20.0

var _base_noise: FastNoiseLite
var _detail_noise: FastNoiseLite


func _init() -> void:
	_setup_noises()


func _generate_block(out_buffer: VoxelBuffer, origin_in_voxels: Vector3i, lod: int) -> void:
	if _base_noise == null or _detail_noise == null:
		_setup_noises()

	var block_size: Vector3i = out_buffer.get_size()
	var stride: int = 1 << lod

	for z in block_size.z:
		for x in block_size.x:
			var wx: float = float(origin_in_voxels.x + x * stride)
			var wz: float = float(origin_in_voxels.z + z * stride)
			var height: float = _sample_height(wx, wz)

			for y in block_size.y:
				var wy: float = float(origin_in_voxels.y + y * stride)
				var sdf: float = wy - height
				out_buffer.set_voxel_f(sdf, x, y, z, VoxelBuffer.CHANNEL_SDF)


func _setup_noises() -> void:
	_base_noise = FastNoiseLite.new()
	_base_noise.seed = noise_seed
	_base_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_base_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_base_noise.fractal_octaves = 4
	_base_noise.frequency = base_frequency

	_detail_noise = FastNoiseLite.new()
	_detail_noise.seed = noise_seed + 911
	_detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_detail_noise.fractal_octaves = 3
	_detail_noise.frequency = detail_frequency


func _sample_height(wx: float, wz: float) -> float:
	var base_n: float = _base_noise.get_noise_2d(wx, wz)
	var detail_n: float = _detail_noise.get_noise_2d(wx, wz)
	var softened_base: float = sign(base_n) * pow(abs(base_n), 1.35)
	var base_h: float = softened_base * base_amplitude
	var detail_h: float = detail_n * detail_amplitude
	return plateau_height + base_h + detail_h
