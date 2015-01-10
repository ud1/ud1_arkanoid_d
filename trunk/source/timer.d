module ud1_arkanoid_d.timer;

import std.datetime;

class Timer {
public:
	this() {
		startTime.start();
		globalStartTime.start();
	}

	final void startTiming() {
		startTime.start();
	}

	double timeElapsed() {
		TickDuration t = startTime.peek();

		elapsed_time = t.nsecs / 1.0e9;
		return elapsed_time;
	}

	double globalTime() {
		TickDuration t = globalStartTime.peek();
		globalStartTime.start();
		global_time += t.nsecs / 1.0e9;
		return global_time;
	}

	void resetGlobalTime(double time = 0.0) {
		globalStartTime.start();
		global_time = time;
	}

	double elapsed_time;
	double global_time;

protected:
	StopWatch startTime;
	StopWatch globalStartTime;
};

class AdvancedTimer: Timer {
public:
	override double timeElapsed() {
		return elapsed_time = Timer.timeElapsed() * time_acceleration;
	}

	override double globalTime() {
		TickDuration t = globalStartTime.peek();
		globalStartTime.start();
		global_time += t.nsecs / 1.0e9 * time_acceleration;
		return global_time;
	}

	final void setTimeAcceleration(double accel) {
		globalTime();
		time_acceleration = accel;
	}

	final double getTimeAcceleration() const {return time_acceleration;}

private:
	double time_acceleration = 1.0;;
};
