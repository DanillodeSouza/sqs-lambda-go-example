package example

import (
	"log"

	"github.com/kelseyhightower/envconfig"
	"go.uber.org/zap/zapcore"
)

//Config represents env configs
type Config struct {
	APP                           string         `envconfig:"APP_NAME" default:"example"`
	LogLevel                      LogLevelConfig `envconfig:"LOG_LEVEL" default:"info"`
}

//NewConfig config constructor
func NewConfig() *Config {
	cfg := &Config{}
	if err := envconfig.Process("", cfg); err != nil {
		log.Fatal(err)
	}
	return cfg
}

// LogLevelConfig log level config.
type LogLevelConfig struct {
	Value zapcore.Level
}

// UnmarshalText implements the encoding.TextUnmarshaler interface.
// The text is expected to have a valid zap level.
func (l *LogLevelConfig) UnmarshalText(text []byte) error {
	level := new(zapcore.Level)
	err := level.Set(string(text))
	l.Value = *level

	return err
}
