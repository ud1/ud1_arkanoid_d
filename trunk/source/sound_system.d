module ud1_arkanoid_d.sound_system;
import derelict.openal.al;
import derelict.ogg.ogg;
import derelict.vorbis.vorbis;
import derelict.vorbis.enc;
import derelict.vorbis.file;
import std.stdio;

enum size_t DYN_BUF_NUMBER	= 3;		// number buffers in queue
enum size_t DYN_BUF_SIZE = 44000*5;	// Buffer size

class Sound {
	this() {
		vrb_file = null;
		source_setted = false;
		looped = false;
		opened = false;
	}

	~this() {
		reset();
	}

	void reset() {
		if (vrb_file) {
			ov_clear(vrb_file);
		}

		if (buffers.length) {
			stop();
			alDeleteBuffers(cast(int)buffers.length, buffers.ptr);
			buffers = null;
		}

		vrb_file = null;
		source_setted = false;
		looped = false;
		opened = false;
	}

	bool open(string filename, bool streamed_) {
		reset();
		streamed = streamed_;

		vrb_file = new OggVorbis_File;

		if (ov_fopen(filename.ptr, vrb_file) < 0) {
			return false;
		}

		vrb_info = ov_info(vrb_file, -1);
		format = (vrb_info.channels == 1) ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16;

		if (streamed) {
			block_size = DYN_BUF_SIZE;
			dyn_bufs = DYN_BUF_NUMBER;
		} else {
			block_size = cast(size_t) (ov_pcm_total(vrb_file, -1)*2*vrb_info.channels);
			dyn_bufs = 1;
		}

		for (size_t i = 0; i < dyn_bufs; ++i) {
			ALuint bufferId;
			alGenBuffers(1, &bufferId);
			if (readOggBlock(bufferId, block_size)) {
				buffers ~= bufferId;
			} else {
				return false;
			}
		}

		opened = true;
		return true;
	}

	bool readOggBlock(ALuint buf_id, size_t size) {
		if (size < 1)
			return false;

		byte[] PCM;
		PCM.length = size;

		size_t total = 0;
		long ret;

		while (total < size) {
			ret = ov_read(vrb_file, &PCM[total], cast(int) (size - total), 0, 2, 1, null);
			if (!ret)
				break;
			total += ret;
		}

		if (total) {
			alBufferData(buf_id, format, &PCM[0], cast(int) (total), vrb_info.rate);
		}

		return total > 0;
	}

	void playOnSource(ALuint source_id_, bool looped_) {
		if (!opened)
			return;

		looped = looped_;
		if (streamed) {
			source_id = source_id_;
			source_setted = true;
			alSourceQueueBuffers(source_id_, cast(int) buffers.length, &buffers[0]);
		} else {
			alSourceStop(source_id_);
			alSourcei(source_id_, AL_BUFFER, buffers[0]);
		}

		alSourcePlay(source_id_);
	}

	void update() {
		if (!source_setted)
			return;

		ALint processed = 0;
		alGetSourcei(source_id, AL_BUFFERS_PROCESSED, &processed);

		while (processed--) {
			ALuint buf_id;
			alSourceUnqueueBuffers(source_id, 1, &buf_id);
			if (readOggBlock(buf_id, DYN_BUF_SIZE)) {
				alSourceQueueBuffers(source_id, 1, &buf_id);
			} else {
				ov_pcm_seek(vrb_file, 0);
				if (readOggBlock(buf_id, DYN_BUF_SIZE)) {
					alSourceQueueBuffers(source_id, 1, &buf_id);
				}
			}
		}
	}

	void stop() {
		if (!source_setted)
			return;

		alSourceStop(source_id);
	}

	OggVorbis_File *vrb_file;
	vorbis_info *vrb_info;
	size_t dyn_bufs, block_size;
	ALenum format;
	ALuint[] buffers;
	bool streamed, source_setted, looped, opened;
	ALuint source_id;
}

enum size_t SOURCE_NUMBER = 5;

struct SoundSystem {
	~this() {
		clear();

		if (sources.length)
			alDeleteSources(cast(int) sources.length, &sources[0]);
		alDeleteSources(1, &backgound_source);
		alDeleteSources(1, &snd_source);
		sources = null;

		alcMakeContextCurrent(null);
		alcDestroyContext(context);
		alcCloseDevice(device);
	}

	bool initialize() {
		device = alcOpenDevice(null); // open default device
		if (!device)
			return false;

		context = alcCreateContext(device, null); // create context
		if (!context) {
			alcCloseDevice(device);
			return false;
		}

		alcMakeContextCurrent(context); // set active context
		alDistanceModel(AL_NONE);

		sources.length = SOURCE_NUMBER;
		alGenSources(SOURCE_NUMBER, &sources[0]);
		alGenSources(1, &backgound_source);
		alGenSources(1, &snd_source);

		snd = new Sound;
		backgound = new Sound;
		initialized = true;
		return true;
	}

	void setSndNumber(size_t count) {
		if (!initialized)
			return;
		clear();

		for (size_t i = 0; i < count; ++i) {
			sounds ~= new Sound;
		}
	}

	bool load(size_t n, string filename) {
		if (!initialized)
			return false;
		assert(n < sounds.length);
		return sounds[n].open(filename, false);
	}

	void play(size_t n, float volume) {
		if (!initialized)
			return;

		if (volume < 0.05f)
			return;

		ALuint source = sources[source_to_play_ind];
		source_to_play_ind = (source_to_play_ind + 1) % sources.length;

		alSourcef(source, AL_GAIN, volume);
		sounds[n].playOnSource(source, false);
	}

	bool play(string filename, float volume) {
		if (!initialized)
			return false;
		if (snd.open(filename, false)) {
			alSourcef(snd_source, AL_GAIN, volume);
			snd.playOnSource(snd_source, false);
			return true;
		}
		return false;
	}

	bool playBackground(string filename, float volume) {
		if (!initialized)
			return false;

		if (!backgound.open(filename, true))
			return false;

		alSourcef(backgound_source, AL_GAIN, volume);
		backgound.playOnSource(backgound_source, true);
		return true;
	}

	void update() {
		if (!initialized)
			return;

		backgound.update();
	}

private:
	void clear() {
		sounds = null;
	}

	Sound[] sounds;
	Sound backgound, snd;
	ALuint[] sources;
	ALuint backgound_source, snd_source;
	size_t source_to_play_ind;
	bool initialized;
	ALCdevice *device;
	ALCcontext *context;
}
