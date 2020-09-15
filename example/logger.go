package example

import (
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// NewLogger returns an usable zap logger.
func NewLogger(logLevel LogLevelConfig) (*zap.Logger, error) {
	logger, err := configLog(zap.NewAtomicLevelAt(logLevel.Value)).Build()
	if err != nil {
		return nil, err
	}
	return logger, nil
}

// LogError logs a error to stderr including some internal information like
// transaction ID, internal ID, error code and message.
func LogError(logger *zap.Logger, start time.Time, transactionID string, msg string, extras map[string]string) {
	logger.Error("failed to process message",
		zap.String("transaction-id", transactionID),
		zap.String("error-message", msg),
		zap.Duration("duration", time.Since(start)),
		zap.Any("extras", extras),
	)
}

// LogDebug logs a debug to stdout when debug Log Level is active
func LogDebug(logger *zap.Logger, transactionID string, msg interface{}) {
	logger.Debug("debug message",
		zap.String("transaction-id", transactionID),
		zap.Any("message", msg),
	)
}

// LogProcessedResult logs processed messages
func LogProcessedResult(logger *zap.Logger, start time.Time, transactionID string, extras map[string]string) {
	logger.Info("processing message result",
		zap.String("transaction-id", transactionID),
		zap.Duration("duration", time.Since(start)),
		zap.Any("extras", extras),
	)
}

func configLog(level zap.AtomicLevel) zap.Config {
	return zap.Config{
		Level:         level,
		Development:   false,
		DisableCaller: true,
		Sampling:      nil,
		Encoding:      "json",
		EncoderConfig: zapcore.EncoderConfig{
			TimeKey:        "time",
			LevelKey:       "level",
			NameKey:        "logger",
			CallerKey:      "caller",
			MessageKey:     "msg",
			LineEnding:     zapcore.DefaultLineEnding,
			EncodeLevel:    zapcore.LowercaseLevelEncoder,
			EncodeTime:     zapcore.ISO8601TimeEncoder,
			EncodeDuration: millisDurationEncoder,
			EncodeCaller:   zapcore.ShortCallerEncoder,
		},
		OutputPaths:      []string{"stdout"},
		ErrorOutputPaths: []string{"stderr"},
	}
}

func millisDurationEncoder(d time.Duration, enc zapcore.PrimitiveArrayEncoder) {
	enc.AppendInt(int(float64(d) / float64(time.Millisecond)))
}
