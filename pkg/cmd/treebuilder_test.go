package cmd

import (
	"github.com/ZupIT/ritchie-cli/pkg/autocomplete"
	"testing"

	"github.com/matryer/is"

	"github.com/ZupIT/ritchie-cli/pkg/credential"
	"github.com/ZupIT/ritchie-cli/pkg/formula"
	"github.com/ZupIT/ritchie-cli/pkg/login"
	"github.com/ZupIT/ritchie-cli/pkg/tree"
	"github.com/ZupIT/ritchie-cli/pkg/user"
	"github.com/ZupIT/ritchie-cli/pkg/workspace"
)

func TestBuildTree(t *testing.T) {
	is := is.New(t)

	treeman := tree.NewDefaultManager("../../testdata", "", nil, nil)

	workman := &workspace.ManagerMock{
		CheckWorkingDirFunc: func() error {
			return nil
		},
		InitWorkingDirFunc: func() error {
			return nil
		},
	}

	credman := &credential.ManagerMock{
		SaveFunc: func(s *credential.Secret) error {
			return nil
		},
		GetFunc: func(provider string) (*credential.Secret, error) {
			return nil, nil
		},
	}

	forman := &formula.ManagerMock{
		RunFunc: func(def formula.Definition) error {
			return nil
		},
	}

	logman := &login.ManagerMock{
		AuthenticateFunc: func(organization string) error {
			return nil
		},
		SessionFunc: func() (*login.Session, error) {
			return &login.Session{}, nil
		},
	}

	userman := &user.ManagerMock{
		CreateFunc: func(user *user.Definition) error {
			return nil
		},
		DeleteFunc: func(user *user.Definition) error {
			return nil
		},
	}

	automan := &autocomplete.ManagerMock{
		HandleFunc: func(string) (s string, err error) {
			return "", nil
		},
	}

	builder := NewTreeBuilder(treeman, workman, credman, forman, logman, userman, automan)
	cmd, err := builder.BuildTree()
	is.NoErr(err)
	is.True(cmd.HasSubCommands())
}