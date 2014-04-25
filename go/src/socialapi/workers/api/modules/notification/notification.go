package notification

import (
	"errors"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"math"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
)

var (
	NOTIFICATION_LIMIT = 8
	ACTOR_LIMIT        = 3
)
func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	q := helpers.GetQuery(u)
	if err := validateNotificationRequest(q); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	list, err := fetchNotifications(q)
	if err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}

		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewOKResponse(list)
}

func Glance(u *url.URL, h http.Header, req *models.Notification) (int, http.Header, interface{}, error) {
	q := models.NewQuery()
	q.AccountId = req.AccountId
	if err := validateNotificationRequest(q); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	if err := req.Glance(); err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}

		return helpers.NewBadRequestResponse(err)
	}

	req.Glanced = true

	return helpers.NewDefaultOKResponse()
}

func Follow(u *url.URL, h http.Header, req *models.Activity) (int, http.Header, interface{}, error) {

	n := models.NewNotification()
	if err := n.Follow(req); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewDefaultOKResponse()
}

type GroupRequest struct {
	Name         string  `json:"name"`
	TypeConstant string  `json:"typeConstant"`
	ActorId      int64   `json:"actorId"`
	Admins       []int64 `json:"admins"`
}

func InteractGroup(u *url.URL, h http.Header, req *GroupRequest) (int, http.Header, interface{}, error) {

	// first fetch channel id as target id
	c := models.NewChannel()
	selector := map[string]interface{}{
		"type_constant": models.Channel_TYPE_GROUP,
		"group_name":    req.Name,
		"name":          req.Name,
	}

	if err := c.One(bongo.NewQS(selector)); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	a := models.NewActivity()
	a.TargetId = c.Id
	a.ActorId = req.ActorId
	a.TypeConstant = req.TypeConstant

	var err error

	n := models.NewNotification()
	switch req.TypeConstant {
	case models.NotificationContent_TYPE_JOIN:
		err = n.JoinGroup(a, req.Admins)
	case models.NotificationContent_TYPE_LEAVE:
		err = n.LeaveGroup(a, req.Admins)
	default:
		err = errors.New("group interaction type not found")
	}
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewDefaultOKResponse()
}

func fetchNotifications(q *models.Query) (*models.NotificationResponse, error) {
	// first check redis
	list, err := fetchCachedNotifications(q.AccountId)
	if err != nil {
		resetCache(q.AccountId)
	} else if len(list.Notifications) > 0 {
		return list, nil
	}

	n := models.NewNotification()
	list, err = n.List(q)
	if err != nil {
		return nil, err
	}

	// store list in cache
	if err := updateCachedNotifications(q.AccountId, list); err != nil {
		fmt.Println("cache cannot be updated", err) // todolog
	}

	return list, nil
}

func validateNotificationRequest(q *models.Query) error {
	a := models.NewAccount()
	a.Id = q.AccountId
	if q.AccountId == 0 {
		return errors.New("Account id cannot be empty")
	}

	if err := a.Fetch(); err != nil {
		if err == gorm.RecordNotFound {
			return errors.New("Account is not valid")
		}
		return err
	}

	// reset the limit if it is needed
	q.Limit = int(math.Min(float64(q.Limit), float64(NOTIFICATION_LIMIT)))

	return nil
}
