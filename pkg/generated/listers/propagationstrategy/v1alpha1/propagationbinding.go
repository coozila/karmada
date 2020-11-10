// Code generated by lister-gen. DO NOT EDIT.

package v1alpha1

import (
	v1alpha1 "github.com/huawei-cloudnative/karmada/pkg/apis/propagationstrategy/v1alpha1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/client-go/tools/cache"
)

// PropagationBindingLister helps list PropagationBindings.
// All objects returned here must be treated as read-only.
type PropagationBindingLister interface {
	// List lists all PropagationBindings in the indexer.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1alpha1.PropagationBinding, err error)
	// PropagationBindings returns an object that can list and get PropagationBindings.
	PropagationBindings(namespace string) PropagationBindingNamespaceLister
	PropagationBindingListerExpansion
}

// propagationBindingLister implements the PropagationBindingLister interface.
type propagationBindingLister struct {
	indexer cache.Indexer
}

// NewPropagationBindingLister returns a new PropagationBindingLister.
func NewPropagationBindingLister(indexer cache.Indexer) PropagationBindingLister {
	return &propagationBindingLister{indexer: indexer}
}

// List lists all PropagationBindings in the indexer.
func (s *propagationBindingLister) List(selector labels.Selector) (ret []*v1alpha1.PropagationBinding, err error) {
	err = cache.ListAll(s.indexer, selector, func(m interface{}) {
		ret = append(ret, m.(*v1alpha1.PropagationBinding))
	})
	return ret, err
}

// PropagationBindings returns an object that can list and get PropagationBindings.
func (s *propagationBindingLister) PropagationBindings(namespace string) PropagationBindingNamespaceLister {
	return propagationBindingNamespaceLister{indexer: s.indexer, namespace: namespace}
}

// PropagationBindingNamespaceLister helps list and get PropagationBindings.
// All objects returned here must be treated as read-only.
type PropagationBindingNamespaceLister interface {
	// List lists all PropagationBindings in the indexer for a given namespace.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1alpha1.PropagationBinding, err error)
	// Get retrieves the PropagationBinding from the indexer for a given namespace and name.
	// Objects returned here must be treated as read-only.
	Get(name string) (*v1alpha1.PropagationBinding, error)
	PropagationBindingNamespaceListerExpansion
}

// propagationBindingNamespaceLister implements the PropagationBindingNamespaceLister
// interface.
type propagationBindingNamespaceLister struct {
	indexer   cache.Indexer
	namespace string
}

// List lists all PropagationBindings in the indexer for a given namespace.
func (s propagationBindingNamespaceLister) List(selector labels.Selector) (ret []*v1alpha1.PropagationBinding, err error) {
	err = cache.ListAllByNamespace(s.indexer, s.namespace, selector, func(m interface{}) {
		ret = append(ret, m.(*v1alpha1.PropagationBinding))
	})
	return ret, err
}

// Get retrieves the PropagationBinding from the indexer for a given namespace and name.
func (s propagationBindingNamespaceLister) Get(name string) (*v1alpha1.PropagationBinding, error) {
	obj, exists, err := s.indexer.GetByKey(s.namespace + "/" + name)
	if err != nil {
		return nil, err
	}
	if !exists {
		return nil, errors.NewNotFound(v1alpha1.Resource("propagationbinding"), name)
	}
	return obj.(*v1alpha1.PropagationBinding), nil
}
